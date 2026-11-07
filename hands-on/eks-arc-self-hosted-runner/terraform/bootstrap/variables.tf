variable "github_config_url" {
  description = "runner を登録する先。https://github.com/<owner>/<repo> か https://github.com/<org>"
  type        = string
}

variable "max_runners" {
  type    = number
  default = 3
}

variable "gitops_repo_url" {
  type    = string
  default = "https://github.com/haruka-aibara/works"
}

variable "gitops_revision" {
  description = "Argo CD が見るブランチ。main にマージする前に試すなら作業ブランチを指定する"
  type        = string
  default     = "main"
}
