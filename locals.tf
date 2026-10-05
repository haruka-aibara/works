locals {
  # HCP Terraform の組織名。tfe_workspace.organization に使う。
  tfe_organization = "haruka-aibara"

  # GitHub の owner 名。provider "github" の owner と vcs_repo.identifier に使う。
  # 移行後は Organization を指す。tfe_organization とは別概念なので分離している。
  github_owner = "haruka-aibara"

  # HCP Terraform 側の VCS 連携（OAuth client）が持つトークンの id。
  # vcs_repo.oauth_token_id に使う。GitHub App 認証（GITHUB_APP_*）とは別物。
  oauth_token_id = data.tfe_oauth_client.this.oauth_token_id

  # provider "aws" の default_tags に入れる、全 AWS リソース共通のタグ。
  # Project はここに入れない。入れると全リソースが同じ Project で
  # コスト配分されるので、アプリごとの alias 付き provider で付ける。
  aws_default_tags = {
    Owner      = "haruka-aibara"
    Terraform  = true
    Repository = "https://github.com/haruka-aibara/works"
  }

  # bedrock-slack-ai-chatbot モジュール専用の provider "aws" に入れるタグ。
  bedrock_slack_ai_chatbot_default_tags = merge(local.aws_default_tags, {
    Environment = "production"
    Project     = "bedrock-slack-ai-chatbot"
  })

  # works の main へのマージに必須にするチェック。
  # ruff・pytest は paths で絞っていて走らない PR があるので入れない（入れると永久に待つ）。
  # Terraform Cloud/... は HCP Terraform の speculative plan。Actions が全部通っても
  # plan だけ落ちることがある（#156 の init 失敗）ので、これも必須にする。
  # repo-id は HCP Terraform が付ける識別子で、PR のチェック欄に出る名前そのまま。
  # Actions のチェック名はジョブの name: そのまま。
  # ワークフローで name: を変えたら、ここも同じ PR で変える。
  works_required_status_checks = [
    "Terraform のフォーマット・構文チェック",
    "Terraform の書き方・AWS 設定値のチェック",
    "Terraform のセキュリティ設定の検査",
    "YAML の構文チェック",
    "GitHub Actions ワークフローの構文チェック",
    "GitHub Actions ワークフローのセキュリティ検査",
    "Markdown の書式チェック",
    "Terraform Cloud/haruka-aibara/repo-id-MdiDoN1E26wzeCUX",
  ]
}
