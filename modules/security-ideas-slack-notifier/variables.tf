variable "slack_channel_id" {
  type        = string
  description = "Slack channel ID that receives the ideas"
}

variable "slack_workspace_id" {
  type        = string
  description = "Slack workspace ID authorized in AWS Chatbot"
}

variable "github_repository" {
  type        = string
  description = "owner/name of the repository whose workflow assumes the role"
}

variable "bedrock_model_id" {
  type        = string
  description = "Bedrock model ID the workflow passes to Claude Code"
  default     = "anthropic.claude-opus-5-5"
}
