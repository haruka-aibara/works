variable "schedule" {
  description = "Config ルールの評価間隔"
  type        = string
  default     = "TwentyFour_Hours"

  validation {
    condition     = contains(["One_Hour", "Three_Hours", "Six_Hours", "Twelve_Hours", "TwentyFour_Hours"], var.schedule)
    error_message = "schedule は One_Hour / Three_Hours / Six_Hours / Twelve_Hours / TwentyFour_Hours のいずれか。"
  }
}

variable "log_retention_in_days" {
  description = "Lambda のログの保持日数"
  type        = number
  default     = 30
}
