variable "instance_type" {
  description = "重ければ c7g.2xlarge に上げる"
  type        = string
  default     = "c7g.xlarge"
}

variable "volume_size" {
  type    = number
  default = 40
}

variable "ts_authkey_param" {
  description = "Tailscale auth key を入れた SSM パラメータ名（SecureString）"
  type        = string
  default     = "/waydroid/ts_authkey"
}

variable "running" {
  description = "false でインスタンスを止める。EBS（Android のデータ）は残る"
  type        = bool
  default     = true
}
