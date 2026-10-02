tags: aws, iam, ai, security, least-privilege

# AI に渡すなら ReadOnlyAccess ではなく ViewOnlyAccess

「AI に AWS を見せるなら読み取り専用で」と言うとき、`ReadOnlyAccess` を選びがち。
でもこれは「設定を読める」ではなく「データも読める」権限。

| 管理ポリシー | 読めるもの |
|---|---|
| `ReadOnlyAccess` | S3 のオブジェクト本体、DynamoDB のアイテム、SSM パラメータの値など、ほぼ全部 |
| `ViewOnlyAccess` | リソースの一覧とメタデータ。データの中身は読まない |
| `SecurityAudit` | セキュリティ設定（ポリシー・暗号化・ログ設定など）の監査向け |

AI に CloudTrail や設定を掘らせたいだけなら、`ReadOnlyAccess` は過剰。
S3 の顧客データや Lambda の環境変数のシークレットまで、AI のコンテキストに入りうる。

## 線の引き方

- 設定の棚卸し・調査：`ViewOnlyAccess` か `SecurityAudit`
- CloudTrail を掘らせる：上に `cloudtrail:LookupEvents` を足すだけ
- データを読ませる必要があるなら、そのバケット・テーブルだけ個別に足す

人間の「閲覧者」ロールも同じ理由で見直す価値がある。

各ポリシーの細かい中身（`ViewOnlyAccess` で何が漏れるか）は、IAM のポリシー画面で実物を確認していない。
