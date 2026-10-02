tags: aws, iam, access-analyzer, terraform, ci, security

# IAM ポリシーの差分を Access Analyzer のカスタムチェックで CI に止めさせる

Terraform の PR で「権限が広がったか」を人間が見抜くのはつらい。
IAM Access Analyzer のカスタムポリシーチェックなら、API で機械的に判定できる。

- `CheckNoNewAccess`：変更前より権限が広がっていないか
- `CheckAccessNotGranted`：`iam:PassRole` や `kms:Decrypt` のような危険なアクションを付けていないか
- `CheckNoPublicAccess`：リソースポリシーが公開になっていないか

## 運用の形

- `terraform plan -out` → `show -json` からポリシーを抜き、変更されたものだけチェックに投げる
- 広がっていたら CI を落とすのではなく、PR に「権限が広がる変更」のラベルを付けて人間の承認を必須にする

AWS が `iam-policy-validator-for-terraform` を出しているので、まずそれで足りるか見る。
`workflow-dist/` で配る候補。

## 気をつけること

- チェック 1 回ごとに課金される。変更されたポリシーだけに絞る
- 自動推論による判定なので、条件キーが複雑なポリシーは判定できないことがある

Claude が出したアイデアで、料金と判定できない条件は公式ドキュメント未確認。
