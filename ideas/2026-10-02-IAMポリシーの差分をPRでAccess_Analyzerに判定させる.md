tags: aws, iam, access-analyzer, terraform, ci, security

# IAM ポリシーの差分を PR で Access Analyzer に判定させる

IAM ポリシーの JSON は、人間が目で追っても `NotAction` などで読み違える。
IAM Access Analyzer のカスタムポリシーチェックを Terraform の PR で回せば、機械的に止められる。

## 使えそうなチェック

| チェック | 何を見るか |
|---|---|
| `CheckNoNewAccess` | 変更前より権限が広がっていないか |
| `CheckAccessNotGranted` | 禁止アクション（`iam:CreateUser`、`kms:ScheduleKeyDeletion` など）が含まれていないか |
| `CheckNoPublicAccess` | バケットポリシー・キーポリシーが公開になっていないか |

## 進め方の案

- `terraform plan` の JSON からポリシーを抜き出す。awslabs に Terraform 用のバリデータがあったはず
- 最初は PR にコメントするだけにして、落とすのは `CheckAccessNotGranted` の禁止リストだけにする
- `CheckNoNewAccess` で落とすと正当な PR も止まる。承認者を増やす合図に使う

## 気をつけること

- チェックは呼び出しごとの課金。差分のあるポリシーだけ投げる
- CI からは OIDC で、検証 API だけ呼べるロールを使う

料金とバリデータの現状は未確認。
関連：[ポリシー生成](<../docs/Amazon Web Services/04_セキュリティ/IAM Access Analyzer/ポリシー生成.md>)
