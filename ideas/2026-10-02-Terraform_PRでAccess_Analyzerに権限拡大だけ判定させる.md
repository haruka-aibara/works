tags: aws, iam, access-analyzer, terraform, github-actions, security

# Terraform PR で Access Analyzer に権限拡大だけ判定させる

IAM ポリシーの差分レビューは、人間が JSON を読んでも「広がったか」が分かりにくい。
Access Analyzer のカスタムポリシーチェックに任せる。

- `check-no-new-access`：変更前と変更後のポリシーを渡し、**新しいアクセスが増えたか**を判定
- `check-access-not-granted`：`iam:PassRole` や `s3:DeleteBucket` など、指定した危険な操作を許していないか判定
- `check-no-public-access`：リソースポリシーが公開になっていないか判定

CI で `terraform plan` の JSON から IAM ポリシーを抜いて叩き、
**FAIL のときだけ PR にコメントする**。広がっていない PR は人間が IAM を読まなくて済む。

## 気をつけること

- 「どこが」広がったかは荒い。FAIL 時は人間が読む
- 1 回ごとに課金される。全ポリシーではなく差分のあるものだけ投げる
- plan の値が `(known after apply)` だとポリシーが確定しない。ARN を変数で組んでいると効きにくい
- AWS 公式の `iam-policy-validator-for-terraform`（tf-policy-validator）がこの用途。自作する前に見る

AI は AWS に繋がず PR まで、の分担でも、CI 側の OIDC ロールに `access-analyzer:Check*` だけ渡せば回る。
