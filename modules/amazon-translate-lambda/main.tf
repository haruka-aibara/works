locals {
  function_name = "amazon-translate-lambda"
}

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

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.this.name
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 30
}

resource "aws_iam_role" "this" {
  name = "${local.function_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# translate:TranslateText と comprehend:DetectDominantLanguage はリソースレベルの権限がない。
# comprehend は SourceLanguageCode = "auto" のときに Translate が呼び出し元の権限で呼ぶ。
resource "aws_iam_role_policy" "this" {
  name = "${local.function_name}-policy"
  role = aws_iam_role.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["translate:TranslateText", "comprehend:DetectDominantLanguage"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.this.arn}:*"
      },
    ]
  })
}
