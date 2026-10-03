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
  # Python CI は paths で絞っていて走らない PR があるので入れない（入れると永久に待つ）。
  # Terraform Cloud/... は HCP Terraform の speculative plan。Actions が全部通っても
  # plan だけ落ちることがある（#156 の init 失敗）ので、これも必須にする。
  # repo-id は HCP Terraform が付ける識別子で、PR のチェック欄に出る名前そのまま。
  works_required_status_checks = [
    "ci / terraform fmt",
    "ci / tflint",
    "ci / trivy (IaC misconfig)",
    "yamllint",
    "actionlint",
    "zizmor",
    "markdownlint",
    "Terraform Cloud/haruka-aibara/repo-id-MdiDoN1E26wzeCUX",
  ]

  # Terraform repositories that should receive the CI caller workflow.
  # Add a line here to onboard a new repo.
  terraform_ci_repos = {
    "works" = { working_directory = "." }
  }

  # Python repositories that should receive the CI caller workflow.
  # Add a line here to onboard a new repo. working_directory is searched for every
  # directory with a pyproject.toml, so a new Lambda inside it needs no change here.
  python_ci_repos = {
    "works" = { working_directory = "." }
  }
}
