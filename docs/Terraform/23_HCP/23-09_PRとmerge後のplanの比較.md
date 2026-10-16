# PR の plan と merge 後の plan の比較

VCS 連携の HCP Terraform で、PR の speculative plan と merge 後の plan が同じかを、GitHub Actions で自動で比べようとした記録。
作ってみてボツにした。

---

## 作ろうとしたもの

`pull_request` の `closed`（merged）で動くワークフロー。

1. PR の head commit の speculative run を探し、plan JSON を取る
2. merge commit の run の plan が終わるのを待ち、plan JSON を取る
3. 整えてから diff し、同じなら成功、違えば失敗にする

結果を見てから Confirm できるよう、ワークスペースの `auto_apply` も切る前提だった。

---

## 調べてわかったこと

### run の探し方

- Runs API の `search[commit]=<SHA>` でコミットから run を探せる
- 一覧はデフォルトで speculative run（`plan_only`）を除くので、PR 側は `filter[operation]=plan_only` を付ける
- PR 側の SHA は `pull_request.head.sha`、merge 後は `pull_request.merge_commit_sha` を payload からそのまま使える
- 同じ SHA の webhook は2回処理されないので、SHA から run は一意に決まる

### plan JSON の取り方と権限

| エンドポイント | 権限 | sensitive な値 | ドキュメント |
|---|---|---|---|
| `/plans/:id/json-output` | ワークスペースの admin | 平文 | あり |
| `/plans/:id/json-output-redacted` | run を読めれば可 | 型に関係なく文字列に置き換わる | なし（Terraform CLI が表示に使っている） |

redacted 版は `timestamp`・`prior_state`・`configuration`・`variables` を含まず、代わりに `provider_schemas` が付いて大きい。

Free プランでは team を作れないので、read 権限だけのトークンは作れない。
どちらを使っても、owners team のトークンを GitHub Secrets に置くことになる。

### そのままの diff では誤検知する

`relevant_attributes` の並び順が、中身が同じでも実行のたびに変わる。

- 一覧は Go の map から作られていて、取り出す順序が毎回違う（`internal/lang/globalref/analyzer_contributing_resources.go`）
- v1.11 で並べ替えが入ったが、比較関数が並べ替え中の配列ではなく元の配列を見ているので、正しく並ばない（`internal/command/jsonplan/plan.go`）
- 同じ処理を取り出して試すと、要素 5 個で 49 通り、20 個ではほぼ毎回違う並びになった

比べるなら `jq '.relevant_attributes |= sort_by(tojson)'` で並べ直す必要がある。

---

## ボツにした理由

- **得られるものが小さい。** PR を main に追いついた状態で merge するなら、コードは同じ。差が出るのはドリフトなどコードの外の変化だけで、個人のリポジトリではまれ
- **払うものが大きい。** owner と同じ権限のトークンを公開リポジトリの Secrets に置く。ドキュメントのない API と Terraform の不具合の回避に頼る
- **本当の目的は別の手段で足りる。** 怖かったのは「想定外の変更が apply される」こと。`auto_apply` を切って Confirm 前に plan を見れば、ほぼ防げる

比べた結果で apply まで止めたいなら、Run Task（post-plan）が筋。
HCP が渡すトークンはその run の plan JSON にしか届かず 10 分で切れるので、権限の問題は消える。
ただし受け口のサーバーを自分で持つことになる。
