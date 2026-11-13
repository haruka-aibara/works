# 複数の Config ルールの非準拠数をまとめた KPI を、CloudWatch ダッシュボードで追う。
# Lambda が定期的にルールごとの NON_COMPLIANT 数を数えてメトリクスに書き、ダッシュボードで合計する。
locals {
  kpi_namespace  = "ConfigCompliance"
  kpi_rule_names = concat([for r in aws_config_config_rule.policy : r.name], var.kpi_extra_rule_names)
  kpi_search     = "SEARCH('{${local.kpi_namespace},RuleName} MetricName=\"NonCompliantResources\"', 'Maximum', 3600)"
}

data "archive_file" "compliance_metrics" {
  type        = "zip"
  output_path = "${path.module}/.build/compliance-metrics.zip"
  source_file = "${path.module}/src/compliance_metrics.py"
}

resource "aws_iam_role" "compliance_metrics" {
  name               = "config-compliance-metrics"
  assume_role_policy = data.aws_iam_policy_document.custodian_assume.json
}

resource "aws_iam_role_policy_attachment" "compliance_metrics_logs" {
  role       = aws_iam_role.compliance_metrics.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "compliance_metrics" {
  statement {
    actions   = ["config:GetComplianceDetailsByConfigRule"]
    resources = ["*"]
  }
  statement {
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = [local.kpi_namespace]
    }
  }
}

resource "aws_iam_role_policy" "compliance_metrics" {
  name   = "compliance-metrics"
  role   = aws_iam_role.compliance_metrics.id
  policy = data.aws_iam_policy_document.compliance_metrics.json
}

resource "aws_cloudwatch_log_group" "compliance_metrics" {
  name              = "/aws/lambda/config-compliance-metrics"
  retention_in_days = var.log_retention_in_days
}

resource "aws_lambda_function" "compliance_metrics" {
  function_name    = "config-compliance-metrics"
  description      = "Config ルールごとの非準拠リソース数を CloudWatch メトリクスに書く"
  filename         = data.archive_file.compliance_metrics.output_path
  source_code_hash = data.archive_file.compliance_metrics.output_base64sha256
  handler          = "compliance_metrics.run"
  runtime          = local.runtime
  role             = aws_iam_role.compliance_metrics.arn
  timeout          = 60

  environment {
    variables = {
      METRIC_NAMESPACE = local.kpi_namespace
      RULE_NAMES       = join(",", local.kpi_rule_names)
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.compliance_metrics.name
  }
}

# ルールの評価は最短でも 1 時間おきなので、それより細かく数えても値は変わらない
resource "aws_cloudwatch_event_rule" "compliance_metrics" {
  name                = "config-compliance-metrics"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "compliance_metrics" {
  rule = aws_cloudwatch_event_rule.compliance_metrics.name
  arn  = aws_lambda_function.compliance_metrics.arn
}

resource "aws_lambda_permission" "compliance_metrics" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.compliance_metrics.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.compliance_metrics.arn
}

data "aws_region" "current" {}

resource "aws_cloudwatch_dashboard" "compliance_kpi" {
  dashboard_name = "config-compliance-kpi"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 6
        height = 6
        properties = {
          title     = "非準拠リソース（現在）"
          view      = "singleValue"
          sparkline = true
          region    = data.aws_region.current.region
          period    = 3600
          metrics = [
            [{ expression = "SUM(${local.kpi_search})", label = "合計", id = "total" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 0
        width  = 18
        height = 6
        properties = {
          title   = "非準拠リソース数の推移（ルール別の積み上げ = 合計）"
          view    = "timeSeries"
          stacked = true
          region  = data.aws_region.current.region
          period  = 3600
          stat    = "Maximum"
          yAxis   = { left = { min = 0, showUnits = false } }
          metrics = [
            [{ expression = local.kpi_search, label = "", id = "rules" }],
          ]
        }
      },
    ]
  })
}
