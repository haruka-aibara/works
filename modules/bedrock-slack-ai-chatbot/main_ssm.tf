# The Slack secrets live here instead of in the Lambda environment, so they are
# not readable from the function configuration. value_wo keeps them out of the
# Terraform state as well: a plain `value` would store them there in clear text.
#
# Standard tier with the AWS managed key (aws/ssm) has no charge.
resource "aws_ssm_parameter" "slack_bot_token" {
  name     = "/${local.project_name}/slack-bot-token"
  type     = "SecureString"
  value_wo = var.slack_bot_token
  # Terraform cannot see a write-only value change. Bump this after rotating
  # the token in the HCP Terraform UI so the new value is written.
  value_wo_version = 1
}

resource "aws_ssm_parameter" "slack_signing_secret" {
  name     = "/${local.project_name}/slack-signing-secret"
  type     = "SecureString"
  value_wo = var.slack_signing_secret
  # See slack_bot_token.
  value_wo_version = 1
}
