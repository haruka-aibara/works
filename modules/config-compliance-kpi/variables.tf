variable "rule_names" {
  description = "非準拠数を合計する Config ルール名"
  type        = list(string)

  validation {
    # DescribeComplianceByConfigRule に一度に渡せるのは 25 個まで
    condition     = length(var.rule_names) > 0 && length(var.rule_names) <= 25
    error_message = "rule_names は 1〜25 個。"
  }
}

variable "schedule_expression" {
  description = "非準拠数を数える間隔（EventBridge Scheduler の式）"
  type        = string
  default     = "rate(1 hour)"
}
