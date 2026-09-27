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

variable "github_config_url" {
  description = "runner を登録する先。https://github.com/<owner>/<repo> か https://github.com/<org>"
  type        = string
}

variable "github_token" {
  description = "runner 登録用の PAT。state に平文で残る"
  type        = string
  sensitive   = true
}

variable "instance_types" {
  description = "Spot の在庫切れに備えて複数指定する"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]
}

variable "capacity_type" {
  type    = string
  default = "SPOT"

  validation {
    condition     = contains(["SPOT", "ON_DEMAND"], var.capacity_type)
    error_message = "SPOT か ON_DEMAND を指定する。"
  }
}

variable "node_count" {
  description = "Cluster Autoscaler / Karpenter を入れていないので、ノード数は固定"
  type        = number
  default     = 1
}

variable "max_runners" {
  type    = number
  default = 3
}

variable "runner_scale_set_name" {
  description = "ワークフローの runs-on に書くラベルになる"
  type        = string
  default     = "eks-arc"
}

variable "arc_chart_version" {
  type    = string
  default = "0.14.2"
}
