tags: terraform, hcp-terraform, aws, iam, oidc, ai, security

# HCP Terraform の speculative plan は apply と同じロールで動くので plan 用ロールを分ける

`works` ワークスペースの AWS 認証は `TFC_AWS_RUN_ROLE_ARN` の1本だけ。
この場合、PR の speculative plan も、apply と同じ書き込み権限つきのロールで動く。

AI は AWS の認証情報を持たず、PR を作るまで、という分担にしている。
でも、ブランチを push すれば plan は走る。
`data "external"` のように plan の時点でコードを実行できる仕組みがあるので、
「AI は AWS に触れない」は、いまは成り立っていない。

## やること

- `TFC_AWS_PLAN_ROLE_ARN` と `TFC_AWS_APPLY_ROLE_ARN` を分ける（未設定なら `RUN_ROLE` が使われる）
- plan 用のロールは `ReadOnlyAccess` 相当にし、信頼ポリシーの `sub` を `...:workspace:works:run_phase:plan` まで絞る
- apply 用のロールは `run_phase:apply` だけに信頼させる

ロールは手で作ったものなので、この機会に Terraform の管理下に入れるかも決める。

## 未確認

- 読み取り専用で plan が通るか。refresh で読むだけなら通るはずだが、`aws_lambda_invocation` のように plan の時点で書き込む data / リソースがないか洗う
- plan 中に外部コマンドから Web Identity トークンを読めるか
