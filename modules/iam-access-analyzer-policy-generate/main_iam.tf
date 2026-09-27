# IAM Access Analyzer サービスロール 許可ポリシー
data "aws_iam_policy_document" "iam_access_analyzer_service_role_permission" {
  statement {
    actions   = ["cloudtrail:GetTrail"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "iam:GetServiceLastAccessedDetails",
      "iam:GenerateServiceLastAccessedDetails"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${local.trail_bucket_name}",
      "arn:aws:s3:::${local.trail_bucket_name}/*"
    ]
  }


}

# IAM Access Analyzer サービスロール 信頼ポリシー
data "aws_iam_policy_document" "iam_access_analyzer_service_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["access-analyzer.amazonaws.com"]
    }
  }
}

# IAM Access Analyzer サービスロール
resource "aws_iam_role" "iam_access_analyzer_service_role" {
  assume_role_policy = data.aws_iam_policy_document.iam_access_analyzer_service_role_assume_role_policy.json
  name               = "AccessAnalyzerMonitorServiceRole_haruka_aibara_test"
}

# IAM Access Analyzer サービスロール用ポリシー
resource "aws_iam_policy" "iam_access_analyzer_service_role" {
  name   = "iam_access_analyzer_service_role_policy"
  policy = data.aws_iam_policy_document.iam_access_analyzer_service_role_permission.json
}

# IAM Access Analyzer サービスロール用ポリシーアタッチメント
resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.iam_access_analyzer_service_role.name
  policy_arn = aws_iam_policy.iam_access_analyzer_service_role.arn
}
