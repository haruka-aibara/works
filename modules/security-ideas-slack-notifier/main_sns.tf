# 通知内容は一般的なアイデアだけなので、CMK までは作らず AWS マネージドキーで暗号化する。
# AWS マネージドキーのキーポリシーが同じアカウントの IAM プリンシパルからの
# SNS 経由の利用を許可するので、publish する側の IAM に kms 権限は要らない。
# trivy:ignore:AWS-0136
resource "aws_sns_topic" "this" {
  name              = "${local.project_name}_topic"
  kms_master_key_id = "alias/aws/sns"
}
