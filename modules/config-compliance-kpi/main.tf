locals {
  namespace = "ConfigCompliance"

  # 1 ステップ目でルールごとの非準拠数を取り、2 ステップ目でルール別と合計をメトリクスに書く。
  # COMPLIANT のルールは ComplianceContributorCount が返らないので 0 として書く。
  definition = {
    QueryLanguage = "JSONata"
    StartAt       = "DescribeCompliance"
    States = {
      DescribeCompliance = {
        Type      = "Task"
        Resource  = "arn:aws:states:::aws-sdk:config:describeComplianceByConfigRule"
        Arguments = { ConfigRuleNames = var.rule_names }
        Output    = "{% $states.result.ComplianceByConfigRules %}"
        Next      = "PutMetrics"
      }
      PutMetrics = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:cloudwatch:putMetricData"
        Arguments = {
          Namespace  = local.namespace
          MetricData = <<-JSONATA
            {% (
              $counts := $states.input.{
                "rule": ConfigRuleName,
                "n": $exists(Compliance.ComplianceContributorCount.CappedCount)
                  ? Compliance.ComplianceContributorCount.CappedCount : 0
              };
              $append(
                $counts.{
                  "MetricName": "NonCompliantResources",
                  "Dimensions": [{ "Name": "RuleName", "Value": rule }],
                  "Value": n,
                  "Unit": "Count"
                },
                [{
                  "MetricName": "NonCompliantResourcesTotal",
                  "Value": $sum($append([0], $counts.n)),
                  "Unit": "Count"
                }]
              )
            ) %}
          JSONATA
        }
        End = true
      }
    }
  }
}

data "aws_region" "current" {}

# --- Step Functions ---

data "aws_iam_policy_document" "sfn_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sfn" {
  name               = "config-compliance-kpi-sfn"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume.json
}

data "aws_iam_policy_document" "sfn" {
  statement {
    actions   = ["config:DescribeComplianceByConfigRule"]
    resources = ["*"]
  }
  statement {
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = [local.namespace]
    }
  }
}

resource "aws_iam_role_policy" "sfn" {
  name   = "count-non-compliant"
  role   = aws_iam_role.sfn.id
  policy = data.aws_iam_policy_document.sfn.json
}

resource "aws_sfn_state_machine" "this" {
  name       = "config-compliance-kpi"
  role_arn   = aws_iam_role.sfn.arn
  definition = jsonencode(local.definition)
}

# --- 定期実行 ---

data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "config-compliance-kpi-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json
}

data "aws_iam_policy_document" "scheduler" {
  statement {
    actions   = ["states:StartExecution"]
    resources = [aws_sfn_state_machine.this.arn]
  }
}

resource "aws_iam_role_policy" "scheduler" {
  name   = "start-execution"
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler.json
}

resource "aws_scheduler_schedule" "this" {
  name                = "config-compliance-kpi"
  schedule_expression = var.schedule_expression

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_sfn_state_machine.this.arn
    role_arn = aws_iam_role.scheduler.arn
  }
}

# --- ダッシュボード ---

resource "aws_cloudwatch_dashboard" "this" {
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
          title     = "非準拠リソース（合計）"
          view      = "singleValue"
          sparkline = true
          region    = data.aws_region.current.region
          period    = 3600
          stat      = "Maximum"
          metrics   = [[local.namespace, "NonCompliantResourcesTotal", { label = "合計" }]]
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
          metrics = [for r in var.rule_names : [local.namespace, "NonCompliantResources", "RuleName", r]]
        }
      },
    ]
  })
}
