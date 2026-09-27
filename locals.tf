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
  # Project はここに入れない。default_tags はモジュール単位で分けられず、
  # 入れると全リソースが同じ Project でコスト配分されるため、
  # モジュールの tags 変数で付ける。
  aws_default_tags = {
    Owner      = "haruka-aibara"
    Terraform  = true
    Repository = "https://github.com/haruka-aibara/works"
  }

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
