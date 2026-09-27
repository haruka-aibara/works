tags: aws, cloudwatch-logs, isms, security, audit

# CloudWatch Logs のロググループでログ保護をどう満たすか

ISMS（ISO/IEC 27002 8.15）の「ログの保護（改ざん防止、アクセス制限）」を、ロググループではどう満たすか。
S3 のバケットポリシーや Object Lock に当たるものが、ロググループにはない。

## 結論

- ログイベントを書き換える API がないので、中身の改ざんは何もしなくても起きない
- 残る経路は「削除」「保持期間の短縮」「偽ログの書き込み」。人間のロールから Deny し、CloudTrail で削除を検知する
- 読み手を絞るのは IAM。リソース側で絞りたければ KMS カスタマー管理キーのキーポリシー
- 単一アカウントでは管理者が Deny ごと外せる。絶対に消せない保証が要るログ（CloudTrail など）は、S3 Object Lock 側で担保する

詳細：[8.15ログ保護をCloudWatch_Logsのロググループで満たす](../docs/ISMS/8.15ログ保護をCloudWatch_Logsのロググループで満たす.md)
