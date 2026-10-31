variable "tfe_organization" {
  type    = string
  default = "haruka-aibara"
}

# UI で発行した team token。Vault に渡したあとは Vault が回すので、
# state に残さないよう ephemeral にして token_wo で渡す。
variable "bootstrap_team_token" {
  type      = string
  sensitive = true
  ephemeral = true
}

variable "rotation_period" {
  type        = number
  description = "Vault が root token を回す間隔（秒）"
  default     = 3600
}
