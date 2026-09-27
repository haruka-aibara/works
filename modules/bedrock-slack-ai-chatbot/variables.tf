variable "slack_bot_token" {
  description = "Slack Bot User OAuth Token"
  type        = string
  sensitive   = true
}

variable "slack_signing_secret" {
  description = "Slack Signing Secret"
  type        = string
  sensitive   = true
}

variable "bedrock_max_tokens" {
  description = "Maximum number of tokens to generate in Bedrock responses"
  type        = number
  default     = 1000
}
