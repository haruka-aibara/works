# 特権 IAM をスナップショットの PR で承認制にする

特権を持つロールやユーザーを自動で見つける。
中身を人が確認して OK を出し、OK を出した時点から変わったらまた気づく。
これを、Git の PR だけで回す。

## 仕組み

private リポジトリに、特権を持つロールやユーザーごとの JSON を置く。
**main ブランチにある JSON が、確認済みのスナップショット**になる。

その private リポジトリの GitHub Actions が毎日、AWS の Lambda を呼ぶ。
判断はすべて Lambda が行い、Actions は言われたとおりに Git と PR を操作するだけにする。

1. Actions が、main にある JSON と、開いている snapshot の PR のブランチにある JSON を集めて Lambda に渡す
2. Lambda が、全ロールと全ユーザーのポリシーを取る（信頼ポリシー・インライン・アタッチした管理ポリシー・ユーザーならグループ経由のもの）
3. Lambda が、特権に当たるステートメントを探し、リソースごとの JSON を作る
4. Lambda が、渡された main と PR のブランチの JSON と比べ、リソースごとに「PR を作る・更新する・閉じる・何もしない」を決める。ファイルの中身、PR のタイトルと本文、Slack の文面まで作って返す
5. Actions が、返された指示どおりにブランチの push と `gh pr create`・`gh pr close` を実行し、Slack に送る

```
GitHub Actions（schedule・毎日）
  ├→ main と開いている PR の JSON を集める
  ├→ OIDC で AWS に入り、決まった Lambda を呼ぶ
  │     └→ Lambda：IAM を読む → 判定 → 過去の JSON と比べる → 操作の一覧と文面を返す
  ├→ 一覧どおりにブランチと PR を操作する（gh CLI）
  └→ Slack に送る（失敗したときも）
```

| 起きたこと | PR の差分 |
|---|---|
| 新しく特権に当たるものが現れた | JSON ファイルが追加される |
| 確認済みのものの特権部分が変わった | その JSON の変わった行が差分に出る |
| 消えた、または特権でなくなった | JSON ファイルが削除される |

**マージが承認**になる。
問題がある変更なら、PR は開けたまま、そのリソースの管理者に AWS 側を直してもらう。
直って main と差分がなくなれば、次の実行で PR を閉じる。手で閉じる必要はない。
別の形の特権に直した場合は、PR が新しい中身で更新されるので、見直してマージする。
直る前に手で閉じても、次の実行で PR がまた作られる。直るまで知らせ続けるので、それでいい。

ブランチの push と PR の作成は、GitHub App のトークンで行う。理由は次の節。

## PR は GitHub App のトークンで作る

`GITHUB_TOKEN` でも PR は作れる。
ただし、`GITHUB_TOKEN` による push や PR では、別の GitHub Actions のワークフローが起動しない。
Actions が Actions を呼び続ける無限ループを防ぐための仕様。

そのため、snapshot の PR で JSON の書式チェックなどの CI を動かせない。
ブランチ保護で「ステータスチェック必須」にすると、チェックが来ないのでマージもできなくなる。

GitHub App のトークンで作った PR なら、ふつうに CI が動く。

App の private key（PEM）は、そのままでは `git push` や `gh` に使えない。
PEM で署名した JWT は「この App である」ことの証明でしかなく、リポジトリは操作できない。
JWT をインストールトークン（対象リポジトリと権限が決まった1時間のトークン）に換えて、初めて使える。
この交換をするのが `actions/create-github-app-token`。

```yaml
- uses: actions/create-github-app-token@v2
  id: app
  with:
    app-id: ${{ vars.SNAPSHOT_APP_ID }}
    private-key: ${{ secrets.SNAPSHOT_APP_PRIVATE_KEY }}

- uses: actions/checkout@v5
  with:
    token: ${{ steps.app.outputs.token }}   # git push を App で

- run: ./snapshot.sh
  env:
    GH_TOKEN: ${{ steps.app.outputs.token }}   # gh pr create を App で
```

PEM はリポジトリシークレットではなく、main ブランチからだけ使える Environment のシークレットに置く。
別のブランチでワークフローを書き換えて実行されても、PEM を読めない。

- GitHub App はインストール先を snapshot リポジトリだけにし、権限は `contents: write` と `pull_requests: write` だけにする
- PR の作成者は App の bot になる。自分が作成者ではないので、「レビュー必須」のブランチ保護でも自分の承認で通せる
- AWS には GitHub の認証情報を何も置かない

外部サービスの連携（HCP Terraform の VCS 連携・Renovate・レビュー用の GitHub App・Slack の GitHub アプリ）は webhook で動くので、`GITHUB_TOKEN` でも止まらない。
止まるのは Actions のワークフローだけ。

## Lambda を挟む理由

Actions が IAM を直接読む構成でも動く。
ただその場合、snapshot リポジトリの main に書き込める人は、ワークフローを書き換えれば IAM の何でも読めてしまう。

Lambda を挟むと、何を読んでどう判定するかは Lambda のコードと実行ロールに固定される。
これらは Terraform 側で管理し、そちらのレビューを通らないと変えられない。
snapshot リポジトリ側をいくら書き換えても、受け取れるのは決まった形のスナップショットだけになる。
権限と判定ロジックを、変更の管理が厳しい側に置ける。

過去の JSON との比べ方、PR を作るか閉じるかの判断、通知の文面も Lambda に持たせる。
Actions のワークフローに残るのは「集める・渡す・言われたとおりに実行する」だけになり、ほとんど変更しなくて済む。
ロジックはすべて Terraform 側の Lambda のコードにあるので、テストもそちらで書ける。

過去の JSON は Actions から渡すので、ワークフローが乗っ取られると、偽の「過去の JSON」を渡して PR を出させないこともできる。
ただ、乗っ取られたワークフローは返された操作を実行しないだけでも同じことができる。Lambda に比較を持たせたことで増える弱点ではない。
守りは、ワークフローを main からしか変えられないようにするブランチ保護と、PEM を main 限定の Environment に置くことで固める。
Lambda が返した操作の一覧を CloudWatch Logs に残しておけば、実際に PR が作られたかをあとから突き合わせられる。

同期呼び出しのリクエストとレスポンスは、それぞれ 6 MB まで。特権のリソースだけの JSON なら十分に収まる。

Lambda は、他の Lambda と同じ運用に乗せられる。
ランタイムの更新・CloudWatch Logs・アラームを、既存のやり方で管理できる。
使うのは標準ランタイムに入っている `boto3` と、標準ライブラリの `json`・`fnmatch` だけなので、レイヤーもいらない。

## PR はリソースごとに1本

PR を1本にまとめると、問題ないロールの変更と問題のあるロールの変更が同じ PR に入り、片方が直るまでもう片方も承認できない。
リソースごとに PR を分ける。

同じリソースで PR が何本も立たないように、ブランチ名をリソースから一意に決める。

- ブランチ名は `snapshot/role/<ロール名>`・`snapshot/user/<ユーザー名>`
- Actions は開いている PR を `gh pr list` で集めて Lambda に渡す。Lambda は、そのブランチに PR があれば「更新」、なければ「作成」を返す
- GitHub も、同じ head と base で開いている PR があると2本目の作成をエラーにする。実装を間違えても二重にはならない
- IAM のロール名はパスが違ってもアカウント内で一意。ロールとユーザーは名前空間が別なので、`role/`・`user/` で分ける
- 消して同じ名前で作り直しても、同じブランチ・同じ PR になる
- ワークフローに `concurrency` を付け、同時に1つしか動かないようにする。手動で実行したときなどに、2つの実行が同時に PR を作りにいくのを防ぐ

## 何を記録するか

ロールやユーザー1つにつき、次の2つだけを記録する。

- **信頼ポリシーの全文**（ロールのみ）：誰がそのロールになれるかは、中身全部が重要
- **特権に当たるステートメントだけ**：どのポリシーに含まれていたかを添える

```json
{
  "trust": { "Version": "2012-10-17", "Statement": [] },
  "privileged_statements": [
    { "source": "aws-managed:AdministratorAccess", "statement": { "Effect": "Allow", "Action": ["*"], "Resource": ["*"] } },
    { "source": "inline:ops", "statement": { "Effect": "Allow", "Action": ["iam:passrole"], "Resource": ["arn:aws:iam::111122223333:role/app"] } }
  ]
}
```

ポリシーの全文は残さない。
特権と関係ない変更（読み取り権限を1つ足したなど）で PR が来なくなる。

AWS 管理ポリシー・カスタマー管理ポリシー・インライン・グループ経由のポリシーを、同じように扱う。
AWS 管理ポリシーは、判定するときだけ中身を取る。
AWS の更新で特権に当たるステートメントが増えたときだけ、差分に出る。
バージョンを追ったり、中身を保存したりはしない。

## 特権の判定

`Effect: Allow` のステートメントの `Action` を、特権とみなす操作の一覧と照らし合わせる。

- ポリシー側の値をワイルドカードのパターンとして扱い、`fnmatch` で照らし合わせる。`*`・`iam:*`・`iam:Pass*` も当たる
- IAM のアクション名は大文字と小文字を区別しないので、両側を小文字にしてから比べる
- `NotAction` があるステートメントは、無条件で当たりにする
- `Condition`・`Resource` での絞り込みや、`Deny` での打ち消しは考えない。当たりにして、人が中身を見て判断する
- サービスリンクロール（パスが `/aws-service-role/`）は除く。AWS が管理していて変えられない

特権とみなす操作の一覧の例：
`iam:AttachRolePolicy`・`iam:PutRolePolicy`・`iam:CreatePolicyVersion`・`iam:UpdateAssumeRolePolicy`・`iam:PassRole`・`iam:CreateAccessKey`・`iam:CreateLoginProfile`・`cloudtrail:StopLogging`・`guardduty:DeleteDetector`・`kms:ScheduleKeyDeletion`

判定は、多めに拾う側に倒す。
人が確認する仕組みなので、見逃すより拾いすぎるほうがいい。

IAM のポリシーシミュレーターは使わない。
条件付きの許可は、条件の値を渡さないと「許可されない」と判定されて見逃す。
特権のステートメントには条件が付いていることが多いので、この用途には向かない。

## 書き出すときの正規化

権限が変わっていないのに差分が出ないようにする。

- `Action`・`Resource` が文字列なら1要素のリストにして、並べ替える
- アクション名を小文字にする
- ステートメントとキーを並べ替える
- 最終使用日時など、毎回変わる項目は入れない

## private リポジトリに置く

スナップショットには、アカウント ID・ロール名・信頼している外部アカウントや IdP が並ぶ。
攻撃者にとっては、どのロールを狙えばいいかの一覧になる。
公開リポジトリには置かない。

## 必要なもの

- **Lambda**：IAM を読んで判定し、スナップショットの JSON を返す。実行ロールの権限は `iam:List*` と `iam:Get*` だけ。コードと実行ロールは Terraform 側で管理する
- **Actions が入るロール**：OIDC で入る。権限はその Lambda の ARN に対する `lambda:InvokeFunction` だけ。信頼ポリシーは、snapshot リポジトリの main ブランチのこのワークフローだけに絞る（`sub` を `repo:<owner>/<repo>:ref:refs/heads/main` で固定）
- **GitHub 側**：snapshot リポジトリだけにインストールした GitHub App（`contents: write`・`pull_requests: write`）。App ID は変数に、private key は main ブランチ限定の Environment のシークレットに置く。ワークフローの `permissions` は、OIDC 用の `id-token: write` と、読み取り用の `contents: read` だけ
- main のブランチ保護と CODEOWNERS で、スナップショットの変更には自分のレビューを必須にする。ワークフローが乗っ取られても、承認は偽れない
- **ジョブが失敗したら Slack に通知する。** 認証が切れたまま黙って止まると、変更がないのと見分けがつかない
- Lambda の実行時間の上限は15分。ロールやユーザーが多い環境では、時間内に収まるかを見ておく

## Slack の通知

通知するかどうかと文面は、Lambda が決める。
Actions は、作った PR の URL を文面に入れて送るだけ。

| 結果 | 通知 |
|---|---|
| PR を新しく作った | 新しい変更がある |
| 開いている PR のブランチを、前回と違う中身で更新した | 前回の PR から中身が変わった |
| 開いている PR と中身が同じ | 通知しない |
| main と差分がなくなったので PR を閉じた | 通知しない |

前回と中身が同じかは、Actions から渡された、そのリソースのブランチの今の中身と比べて判定する。

1回の実行で通知は1件だけにして、新規・変更・削除のリソースを PR へのリンク付きで並べる。

```
特権 IAM の変更があります
新規: role/ci-deploy（PR #12）
変更: role/breakglass（PR #13）
```

## やらないこと・できないこと

- **侵入の検知ではない。** 1日1回の実行なので、作ってすぐ使って消された特権ロールは記録に残らない。それは GuardDuty や CloudTrail の役目。これは「今ある特権を全部見て、OK を出した状態を保つ」ための仕組み。即時に近づけるなら次の節
- SCP やリソースポリシーは見ない。ロールやユーザー自身のポリシーだけを見る
- 対象は1アカウント。複数アカウントなら、各アカウントに読み取り用のロールを置く

## 即時にするなら（あとから足す）

IAM の変更をきっかけに、同じワークフローを起動する。

```
CloudTrail（IAM の変更）→ EventBridge のルール（us-east-1）→ API 送信先 → GitHub の workflow_dispatch
```

- EventBridge の API 送信先（API Destination）から、GitHub の `workflow_dispatch` API を直接呼ぶ。Lambda はいらない
- 必要な GitHub の権限は **Actions の write だけ**。コードも PR も触れないので、漏れても main にある決まったワークフローを起動されるだけ
- 連続したイベントは、ワークフローの `concurrency` でまとまる。同じグループでは実行中1つと待ち1つだけが残り、それ以外の待ちは取り消される。Terraform の apply 1回で何十件もイベントが出ても、実行は2回までに収まる
- API 送信先には呼び出し回数の上限を設定できる。イベントが大量に来ても、GitHub に流れすぎない
- EventBridge のルールは us-east-1 に置く。IAM はグローバルサービスで、イベントは us-east-1 に届く
- 対象は特権が変わりうる操作だけにする（`AttachRolePolicy`・`PutRolePolicy`・`UpdateAssumeRolePolicy`・`CreatePolicyVersion`・`AddUserToGroup` など）。インスタンスプロファイルの付け外し・タグ付け・サービスリンクロールの作成は入れない
- Kubernetes のコントローラー（Karpenter・ACK・Crossplane など）がロールを高速に作ったり消したりする環境では、`userIdentity.arn` の `anything-but` でコントローラーの操作を外す。作られる側ではなく作る側を見張る。コントローラーのロールは `iam:CreateRole` と `iam:PassRole` を持つので、スナップショットに入る。作るロールにはアクセス許可の境界を必ず付けさせ（`iam:PermissionsBoundary` の条件付きでだけ `CreateRole` を許す）、定期実行でもそのパスやプレフィックスを除外する

## 除外条件に使っているロールについて

SCP やバケットポリシーで特定のロールを Deny から除外しているなら、そのロールはほぼ確実に特権に当たる。
この仕組みで、除外したあとの権限や信頼ポリシーの変化にも気づける。

合わせてやっておくこと。

- 除外を `aws:PrincipalArn` で書くと、同じ名前で作り直されたロールにも除外が効く。
  `aws:userid`（`AROA...:*`）で書けば、作り直すと一意な ID が変わるので除外から外れる
- 除外したロールの変更は、SCP で Terraform の実行ロール以外に禁止する

## 検討してやめた案

- **Terraform の `check` ブロックで、確認時点の JSON と比べる**：plan を実行しないと気づけない。見張るロールを手で列挙する必要がある。AWS 管理ポリシーの中身まで比べると、AWS の更新のたびに警告が出る
- **AWS 管理ポリシーのバージョンを追う**：更新の大半は特権と関係ない。特権に当たるステートメントだけを記録すれば、追う必要がなくなる
- **Actions が IAM を直接読む**：部品は最も少ない。ただ、snapshot リポジトリのワークフローを書き換えれば、IAM の何でも読めてしまう
- **EventBridge Scheduler と Lambda で実行し、Lambda から PR を作る**：snapshot リポジトリに書き込める GitHub App の private key を、AWS に常に置くことになる。PR を操作するコードも GitHub API で自分で書く必要がある。即時にするときも、連続したイベントをまとめるのに SQS と同時実行数の制御が要る
- **AWS Config・Security Hub CSPM**：変更の記録や `*:*` の検出はできるが、「確認して OK を出した状態」を持てない

## 未確認

- `aws:userid` を SCP の条件で使ったときに、上のとおりに動くか
- `concurrency` で待ちが1つに絞られる動きが、`workflow_dispatch` で起動した実行にも同じように効くか
