## For Chatbot
resource "aws_iam_role" "chatbot" {
  name               = "${local.project_name}-chatbot-role"
  assume_role_policy = data.aws_iam_policy_document.chatbot_assume_role.json
}

data "aws_iam_policy_document" "chatbot_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["chatbot.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "chatbot" {
  statement {
    effect = "Allow"
    actions = [
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:AddPermission",
      "sns:RemovePermission",
      "sns:DeleteTopic",
      "sns:ListSubscriptionsByTopic"
    ]
    resources = [aws_sns_topic.this.arn]
  }
}

resource "aws_iam_policy" "chatbot" {
  name        = "${local.project_name}-chatbot-policy"
  description = "${local.project_name}-chatbot-policy"
  policy      = data.aws_iam_policy_document.chatbot.json
}

resource "aws_iam_role_policy_attachment" "chatbot" {
  role       = aws_iam_role.chatbot.name
  policy_arn = aws_iam_policy.chatbot.arn
}

## For GitHub Actions
# アカウントに GitHub の OIDC プロバイダーは URL ごとに 1 つしか作れない。
# 手で作ったものが既にあるなら、apply 前に import ブロックで取り込む。
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# main で動くワークフロー（schedule と workflow_dispatch）だけが引き受けられる。
# PR やほかのブランチからは引き受けられないので、ワークフローを書き換えた PR が
# Bedrock を叩いたり Slack に投げたりはできない。
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = "${local.project_name}-github-actions-role"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_assume_role.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "github_actions" {
  statement {
    sid       = "PublishIdeas"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.this.arn]
  }

  # クロスリージョン推論プロファイル経由だと、プロファイルと転送先リージョンの
  # 基盤モデルの両方に権限が要る。
  statement {
    sid    = "InvokeClaude"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    resources = [
      "arn:aws:bedrock:*::foundation-model/${var.bedrock_model_id}",
      "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/*.${var.bedrock_model_id}",
    ]
  }
}

resource "aws_iam_policy" "github_actions" {
  name        = "${local.project_name}-github-actions-policy"
  description = "${local.project_name}-github-actions-policy"
  policy      = data.aws_iam_policy_document.github_actions.json
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
