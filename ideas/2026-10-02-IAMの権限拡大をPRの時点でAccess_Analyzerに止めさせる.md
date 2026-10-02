tags: aws, iam, access-analyzer, terraform, ci, security

# IAM の権限拡大を PR の時点で Access Analyzer に止めさせる

IAM Access Analyzer のカスタムポリシーチェックを CI に入れ、`terraform plan` の差分に権限拡大があれば止める。
AI が IAM ポリシーを書く流れでも、見落としやすい箇所を機械が見る。

## 使える API

- `CheckNoNewAccess`：変更前より権限が増えていないか
- `CheckAccessNotGranted`：`iam:PassRole` や `s3:DeleteBucket` など、指定したアクションを許していないか
- `CheckNoPublicAccess`：リソースポリシーが公開になっていないか

plan の JSON からポリシーを抜き出す部分は、awslabs の Terraform 向けポリシーバリデーター（`tf-policy-validator`）が使えそう（未確認）。

## 「止める」ではなく「人間に回す」

権限が増える PR は正当なものも多い。
「権限拡大あり」ラベルをつけて人間の承認を必須にするくらいがちょうどいい。
AI は PR 作成まで、マージは人間という分担にそのまま乗る。

## 気になる点

- チェックは1回ごとに課金される。PR のたびに全ポリシーを投げるのではなく、差分のあるポリシーだけに絞る
- CI から AWS に接続することになる。AI のエージェントには渡さず、GitHub Actions の OIDC ロールに `access-analyzer:Check*` だけ持たせる
