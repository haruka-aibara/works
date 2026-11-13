# 複数の Config ルールの非準拠数をまとめた KPI を、CloudWatch ダッシュボードで追う。
# 数えるのは各ルールの Lambda で動く c7n 自身で、評価のたびに一致したリソース数を
# CloudMaid/ResourceCount（ディメンション Policy / ResType / Scope）に書く（locals.tf の metrics_enabled）。
locals {
  # データ点は評価 1 回につき 1 つなので、評価間隔と同じ期間で集計する
  kpi_period = {
    One_Hour         = 3600
    Three_Hours      = 10800
    Six_Hours        = 21600
    Twelve_Hours     = 43200
    TwentyFour_Hours = 86400
  }[var.schedule]
  kpi_search = "SEARCH('{CloudMaid,Policy,ResType,Scope} MetricName=\"ResourceCount\"', 'Maximum', ${local.kpi_period})"
}

data "aws_iam_policy_document" "custodian_metrics" {
  statement {
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CloudMaid"]
    }
  }
}

resource "aws_iam_role_policy" "custodian_metrics" {
  name   = "cloudwatch-metrics"
  role   = aws_iam_role.custodian.id
  policy = data.aws_iam_policy_document.custodian_metrics.json
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
          period    = local.kpi_period
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
          period  = local.kpi_period
          yAxis   = { left = { min = 0, showUnits = false } }
          metrics = [
            [{ expression = local.kpi_search, label = "", id = "rules" }],
          ]
        }
      },
    ]
  })
}
