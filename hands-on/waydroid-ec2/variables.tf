variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "instance_type" {
  description = "重ければ c7g.2xlarge に上げる"
  type        = string
  default     = "c7g.xlarge"
}

variable "volume_size" {
  type    = number
  default = 40
}

variable "subnet_id" {
  description = "空ならデフォルト VPC のサブネットを1つ選ぶ。c7g が無い AZ に当たったら指定する"
  type        = string
  default     = ""
}

variable "ts_authkey_param" {
  description = "Tailscale auth key を入れた SSM パラメータ名（SecureString）"
  type        = string
  default     = "/waydroid/ts_authkey"
}
