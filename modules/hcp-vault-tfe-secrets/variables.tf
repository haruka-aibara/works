variable "organization" {
  type = string
}

variable "configure_secrets_engine" {
  type        = bool
  description = "Mount and configure the secrets engine. Leave false until bootstrap_team_token holds a real token of the vault-root team."
  default     = false
}

variable "bootstrap_team_token" {
  type        = string
  description = "A team token of the vault-root team, issued in the UI. Vault rotates it away, so it is only ever written once."
  sensitive   = true
  ephemeral   = true
  default     = null
}

variable "rotation_period" {
  type        = number
  description = "Seconds between Vault's automated rotations of its root token."
  default     = 3600
}
