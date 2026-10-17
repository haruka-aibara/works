locals {
  function_name = "amazon-translate-lambda"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# zip の出力先は source_dir の外（.build/）に置く。中に置くと前回の zip が次の zip に入り込む。
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function"
  output_path = "${path.module}/.build/lambda_function.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = local.function_name
  role             = aws_iam_role.this.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  architectures    = ["arm64"]
  timeout          = 10
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  # 呼ばれすぎて Translate の課金が膨らむのを防ぐ。試すだけなら 1 本で足りる。
  reserved_concurrent_executions = 1

  logging_config {
    log_format            = "JSON"
    log_group             = aws_cloudwatch_log_group.this.name
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }

  tracing_config {
    mode = "Active"
  }

  # ロールにポリシーが付く前に関数ができると、最初の呼び出しが権限不足で落ちる。
  depends_on = [aws_iam_role_policy.this]
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.logs.arn
}

# =========================================
# KMS（ロググループの暗号化）
# =========================================

resource "aws_kms_key" "logs" {
  description             = "${local.function_name} log group"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.kms_logs.json
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${local.function_name}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

data "aws_iam_policy_document" "kms_logs" {
  statement {
    sid       = "AccountAdmin"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # CloudWatch Logs が使えるのは、このロググループの暗号化に限る。
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.function_name}"]
    }
  }
}

# =========================================
# IAM
# =========================================

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    # 他アカウントの Lambda からこのロールを使わせない（confused deputy 対策）。
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "this" {
  # translate:TranslateText と comprehend:DetectDominantLanguage はリソースレベルの権限がない。
  # comprehend は SourceLanguageCode = "auto" のときに Translate が呼び出し元の権限で呼ぶ。
  statement {
    sid    = "Translate"
    effect = "Allow"
    actions = [
      "translate:TranslateText",
      "comprehend:DetectDominantLanguage",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
  }

  # X-Ray もリソースレベルの権限がない。
  statement {
    sid    = "XRay"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${local.function_name}-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}
