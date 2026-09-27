tags: isms, aws, aws-backup, terraform, audit

# ISMS 8.13 情報のバックアップは AWS Backup の Vault Lock で満たす

[クロック同期](2026-09-26-ISMSのクロック同期はAWSでは何をやるか.md)・[ログ保護](2026-09-26-CloudWatch_Logsのロググループでログ保護をどう満たすか.md) の続き。
バックアップで問われるのは「取っているか」より「消されない・戻せるか」。

## 結論

- 取るのは AWS Backup のバックアッププランで足りる（EBS / RDS / DynamoDB / EFS / S3 をまとめて扱える）
- 「消されない」は Vault Lock の compliance モードで満たす。猶予期間（最短3日）を過ぎると、root でも AWS でもロックを外せず、復旧ポイントを保持期間内に消せなくなる
- 「戻せるか」は restore testing で定期的に試し、その結果を証跡にする

## Terraform で気をつけること

`aws_backup_vault_lock_configuration` の `changeable_for_days` を設定したら、猶予期間のうちに設定を見直す。
過ぎたら、保持期間の設定ミスも含めて直せない。
最初は `changeable_for_days` を付けない governance モードで試す。
S3 だけなら、Object Lock を直接かけるほうが素直。

## 未確認

restore testing の結果が、監査の証跡としてそのまま使える形で残るか。
