# 特権 IAM をスナップショットの PR で承認制にする

特権を持つロールやユーザーを自動で見つける。
中身を人が確認して OK を出し、OK を出した時点から変わったらまた気づく。
これを、Git の PR だけで回す。

## 仕組み

private リポジトリに、特権を持つロールやユーザーごとの JSON を置く。
**main ブランチにある JSON が、確認済みのスナップショット**になる。

```
GitHub Actions（schedule・毎日）
  ├→ checkout
  ├→ OIDC で AWS に入り、決まった Lambda を呼ぶ
  │     └→ Lambda：IAM を読む → 特権を判定 → 今の JSON を返す
  ├→ 返った JSON でスナップショットのディレクトリを置き換える
  ├→ git status で変わったファイルを見て、ファイルごとにブランチと PR を作る・更新する
  └→ Slack に通知
```

役割は次のように分ける。

- **Lambda：何が特権か。** IAM を読み、判定し、今の JSON を返す。入力は IAM、出力は JSON の単純な関数で、Git のことは知らない
- **Actions：Git の操作。** 差分は `git diff` が出すので、自分で書く判断はない

| 起きたこと | PR の差分 |
|---|---|
| 新しく特権に当たるものが現れた | JSON ファイルが追加される |
| 確認済みのものの特権部分が変わった | その JSON の変わった行が差分に出る |
| 消えた、または特権でなくなった | JSON ファイルが削除される |

**マージが承認**になる。
問題がある変更なら、PR は開けたまま、そのリソースの管理者に AWS 側を直してもらう。
直って main と差分がなくなれば、次の実行で PR を閉じる。
直る前に手で閉じても、次の実行で PR がまた作られる。直るまで知らせ続けるので、それでいい。

## Lambda を挟む理由

Actions が IAM を直接読んでも動く。
ただその場合、snapshot リポジトリの main に書き込める人は、ワークフローを書き換えれば IAM の何でも読めてしまう。

Lambda を挟むと、何を読んでどう判定するかは Lambda のコードと実行ロールに固定される。
これらは Terraform 側で管理し、そちらのレビューを通らないと変えられない。
Actions に許すのは、その Lambda を呼ぶことだけになる。

Lambda は他の Lambda と同じ運用（ランタイムの更新・CloudWatch Logs・アラーム）に乗せられる。
使うのは `boto3` と標準ライブラリの `json`・`fnmatch` だけなので、レイヤーもいらない。

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

ポリシーの全文は残さない。特権と関係ない変更で PR が来なくなる。
AWS 管理ポリシー・カスタマー管理ポリシー・インライン・グループ経由のポリシーを同じように扱う。
AWS の更新で特権に当たるステートメントが増えたときだけ、差分に出る。

## 特権の判定

`Effect: Allow` のステートメントの `Action` を、特権とみなす操作の一覧と `fnmatch` で照らし合わせる。

- ポリシー側の値をパターンとして扱う。`*`・`iam:*`・`iam:Pass*` も当たる
- 両側を小文字にしてから比べる。IAM のアクション名は大文字と小文字を区別しない
- `NotAction` があるステートメントは、無条件で当たりにする
- `Condition`・`Resource` での絞り込みや `Deny` は考えない。多めに拾って、人が見て判断する
- サービスリンクロール（パスが `/aws-service-role/`）は除く

### 一覧は Cloudsplaining から作る

特権とみなす操作の一覧は、[Cloudsplaining](https://github.com/salesforce/cloudsplaining)（Salesforce 発の OSS、MIT ライセンス）がかなりいい参考になる。
`cloudsplaining/shared/constants.py` に、判定に使う一覧がそのまま置いてある。

- `PRIVILEGE_ESCALATION_METHODS`：権限昇格の手口 59 件（Rhino Security Labs の調査が元）。単品で成立するもの 16 件と、複数の操作がそろって成立するもの 43 件
- `ACTIONS_THAT_RETURN_CREDENTIALS`：認証情報を返す操作 45 件
- `READ_ONLY_DATA_EXFILTRATION_ACTIONS`：持ち出しにつながる読み取り操作（S3・SSM パラメータストア・Secrets Manager）

最初は単品の判定だけにして、手口ごとの中心の操作を一覧に入れる。

- 組み合わせの手口のうち 24 件は `iam:PassRole` を含むので、`iam:PassRole` を一覧に入れれば単品の判定で拾える
- 残りは、中心の操作（`lambda:UpdateFunctionCode`・`ec2:ModifyInstanceAttribute`・`cloudformation:ExecuteChangeSet` など）を単品として入れれば、多めに拾う側で拾える

自分で思いつく範囲で一覧を作ると抜けが出る。
たとえば `iam:AttachRolePolicy`・`iam:PassRole` などだけで作った一覧は、Cloudsplaining の 59 件のうち 19 件を拾えなかった。
`iam:AttachUserPolicy`・`iam:AttachGroupPolicy`・`iam:PutUserPolicy`・`iam:PutGroupPolicy`・`iam:AddUserToGroup`・`iam:UpdateLoginProfile`・`iam:SetDefaultPolicyVersion`・`lambda:UpdateFunctionCode` などが抜けていた。

これに、検知や証跡を止める操作（`cloudtrail:StopLogging`・`guardduty:DeleteDetector`・`kms:ScheduleKeyDeletion` など）を自分で足す。
Cloudsplaining は権限昇格と持ち出しが中心で、検知を止める操作は扱っていない。

IAM のポリシーシミュレーターは使わない。
条件付きの許可は、条件の値を渡さないと「許可されない」と判定されて見逃す。

JSON は、`Action`・`Resource` をリストにして並べ替え、キーとステートメントも並べ替えて出す。
権限が変わっていないのに差分が出ないようにするため。

## PR はリソースごとに1本

1本にまとめると、問題ない変更と問題のある変更が同じ PR に入り、片方が直るまでもう片方も承認できない。

- ブランチ名をリソースから一意に決める（`snapshot/role/<ロール名>`・`snapshot/user/<ユーザー名>`）
- そのブランチの PR が `gh pr list --head` で見つかれば更新、なければ `gh pr create`
- GitHub も、同じ head と base で開いている PR があると2本目をエラーにするので、二重にはならない
- ワークフローに `concurrency` を付け、同時に1つしか動かないようにする

Slack には、1回の実行につき1件だけ、作った・更新した PR へのリンクを並べて送る。
PR が開いたままで中身も同じなら、送らない。

## PR は GitHub App のトークンで作る

`GITHUB_TOKEN` で作った PR や push では、別の GitHub Actions のワークフローが起動しない（無限ループを防ぐための仕様）。
snapshot の PR で CI を動かしたり、「ステータスチェック必須」にしたりできなくなる。
GitHub App のトークンで作れば、ふつうに CI が動く。

App の private key（PEM）は、そのままでは使えない。
PEM で署名した JWT を、対象リポジトリと権限が決まった1時間のインストールトークンに換えて使う。
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

PR の作成者は App の bot になるので、「レビュー必須」のブランチ保護でも自分の承認で通せる。

## 必要なもの

- **snapshot リポジトリ**：private にする。特権ロールの一覧は、攻撃者にとって狙うべきロールの一覧になる
- **Lambda**：実行ロールの権限は `iam:List*` と `iam:Get*` だけ。コードと実行ロールは Terraform 側で管理する
- **Actions が入るロール**：OIDC で入り、権限はその Lambda に対する `lambda:InvokeFunction` だけ。信頼ポリシーの `sub` を snapshot リポジトリの main に固定する
- **GitHub App**：インストール先は snapshot リポジトリだけ。権限は `contents: write` と `pull_requests: write` だけ。PEM は main ブランチからだけ使える Environment のシークレットに置く
- **main のブランチ保護と CODEOWNERS**：スナップショットの変更には自分のレビューを必須にする
- **失敗の通知**：ジョブが失敗したら Slack に送る。黙って止まると、変更がないのと見分けがつかない

## やらないこと

- **侵入の検知ではない。** 1日1回なので、作ってすぐ消された特権は残らない。それは GuardDuty や CloudTrail の役目
- SCP やリソースポリシーは見ない
- 対象は1アカウント

## あとから足すもの

困ってから足せば間に合う。

- **即時の実行**：IAM の変更を EventBridge のルール（us-east-1）で拾い、API 送信先から `workflow_dispatch` を呼ぶ。GitHub の権限は Actions の write だけで済み、連続したイベントは `concurrency` でまとまる。Kubernetes のコントローラーのように高速にロールを作るものは、`userIdentity.arn` で除外し、作る側の権限とアクセス許可の境界で抑える
- **大きくなったら**：Lambda のレスポンスは 6 MB まで。超えそうなら、Lambda が S3 に書いて場所だけ返す
- **組み合わせの判定**：Cloudsplaining の手口のように「`iam:PassRole` と `ec2:RunInstances` の両方」で当たりにする。新しく拾うためではなく、本当に危ないものだけに絞って誤検知を減らすためのもの。単品の判定で PR が多すぎると感じてから足す
- **初回の PR の数**：全部が新規になるので、1回で作る PR の数に上限を付ける
- **除外条件に使っているロール**：SCP などで除外しているロールは、ほぼ確実に特権に当たるので、この仕組みで変化に気づける。除外は `aws:PrincipalArn` ではなく `aws:userid`（`AROA...:*`）で書くと、同じ名前で作り直されたロールに効かない

## 検討してやめた案

- **Terraform の `check` ブロックで確認時点と比べる**：plan を実行しないと気づけず、見張るロールを手で並べる必要がある
- **Actions が IAM を直接読む**：ワークフローを書き換えれば IAM の何でも読める
- **全部 Lambda でやる**：Git との比較を Git の外からやることになり、API の上限や SHA の計算方法の一致など小細工が増える。PEM も AWS に置くことになる
- **AWS 管理ポリシーのバージョンを追う**：更新の大半は特権と関係ない
- **AWS Config・Security Hub CSPM**：「確認して OK を出した状態」を持てない
- **既存の OSS・SaaS をそのまま使う**：Cloudsplaining・Prowler・ScoutSuite は検出まで。Cloudsplaining は OK にしたものを名前で除外するので、除外した後に中身が変わっても気づけない。CIEM の SaaS（Wiz・Orca など）は個人のアカウントには大きすぎる

## 未確認

- `aws:userid` を SCP の条件で使ったときに、上のとおりに動くか
- `concurrency` で待ちが1つに絞られる動きが、`workflow_dispatch` で起動した実行にも同じように効くか
