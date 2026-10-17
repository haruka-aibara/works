locals {
  function_name = "amazon-translate-lambda"
}

data "aws_caller_identity" "current" {}

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

  # ロールにポリシーが付く前に関数ができると、最初の呼び出しが権限不足で落ちる。
  depends_on = [aws_iam_role_policy.this]
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 30
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
}

resource "aws_iam_role_policy" "this" {
  name   = "${local.function_name}-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}
