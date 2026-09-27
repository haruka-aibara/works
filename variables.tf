variable "bedrock_slack_ai_chatbot_slack_bot_token" {
  description = "Slack Bot User OAuth Token for the bedrock-slack-ai-chatbot module"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "bedrock_slack_ai_chatbot_slack_signing_secret" {
  description = "Slack Signing Secret for the bedrock-slack-ai-chatbot module"
  type        = string
  sensitive   = true
  ephemeral   = true
}

# The short-cycle verification in docs/runbooks/tfe-token-rotation.md sets these
# as workspace Terraform variables, so they stay declared at the root. Left
# unset (null), module "tfe_team_token_rotation" falls back to its own defaults.
variable "rotation_minutes" {
  type        = number
  description = "Overrides module.tfe_team_token_rotation's rotation_minutes. Leave unset outside the short-cycle verification."
  default     = null
}

variable "buffer_minutes" {
  type        = number
  description = "Overrides module.tfe_team_token_rotation's buffer_minutes. Leave unset outside the short-cycle verification."
  default     = null
}

# For module "aws_budget_slack_notifier" in main.tf, which is commented out for
# now. Uncomment together with that module.
# variable "budget_slack_channel_id" {
#   type        = string
#   description = "Slack channel ID that receives AWS Budgets notifications"
# }
#
# variable "budget_slack_workspace_id" {
#   type        = string
#   description = "Slack workspace ID authorized in AWS Chatbot"
# }
#
# variable "budget_limit_amount_daily" {
#   type        = number
#   description = "Daily cost (USD) above which AWS Budgets notifies Slack"
# }

# For module "bedrock_agent_classic_slack" in main.tf, which is commented out
# for now. Uncomment together with that module.
# variable "bedrock_agent_slack_team_id" {
#   type        = string
#   description = "Slack workspace ID authorized in Amazon Q Developer in chat applications (formerly AWS Chatbot)"
# }
#
# variable "bedrock_agent_slack_channel_id" {
#   type        = string
#   description = "Slack channel ID where the Bedrock agent connector is used"
# }

# For module "generate_dev_io_summary" in main.tf, which is commented out for
# now. Uncomment together with that module.
# variable "generate_dev_io_summary_slack_channel_id" {
#   type        = string
#   description = "Slack channel ID that receives the DevelopersIO summaries"
# }
#
# variable "generate_dev_io_summary_slack_workspace_id" {
#   type        = string
#   description = "Slack workspace ID authorized in AWS Chatbot"
# }

# For module "google_cloud_hands_on" in main.tf, which is commented out for
# now. Uncomment together with that module.
# variable "google_cloud_hands_on_project_id" {
#   type        = string
#   description = "Google Cloud project ID that gets the budget alert"
# }
#
# variable "google_cloud_hands_on_billing_account_id" {
#   type        = string
#   description = "Google Cloud billing account ID the budget belongs to"
# }
