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

variable "tags" {
  description = "Tags for this module's resources, on top of the provider's default_tags (e.g. Project for cost allocation)"
  type        = map(string)
  default     = {}
}
