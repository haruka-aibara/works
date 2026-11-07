variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "name" {
  description = "クラスタ名や各リソースの名前に使う"
  type        = string
  default     = "arc-hands-on"
}

variable "api_allowed_cidrs" {
  description = "EKS の API に手元からつなぐ元の CIDR。例: [\"203.0.113.10/32\"]"
  type        = list(string)
}

variable "github_app_secret_name" {
  description = "GitHub App の認証情報を入れた Secrets Manager のシークレット名。Terraform の外で作っておく"
  type        = string
  default     = "arc-hands-on/github-app"
}
