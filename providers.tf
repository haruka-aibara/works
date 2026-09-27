# https://registry.terraform.io/providers/integrations/github/latest/docs
provider "github" {
  owner = local.github_owner
  # See docs/reference/github-authentication.md for what these are.
  # Authentication comes from the GITHUB_APP_ID / GITHUB_APP_INSTALLATION_ID /
  # GITHUB_APP_PEM_FILE environment variables on HCP Terraform, declared in
  # main.tf. The provider reads the GITHUB_APP_ prefix without an
  # app_auth block and mints a one-hour installation token per run.
}

# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs
provider "tfe" {
  # TFE_TOKEN is already set as an environment variable on HCP Terraform Cloud
  # organization is set per resource
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs
# Default AWS provider. Authenticates via HCP Terraform's
# dynamic provider credentials (OIDC) instead of static keys: the
# TFC_AWS_PROVIDER_AUTH / TFC_AWS_RUN_ROLE_ARN workspace variables are set in
# the UI (they aren't secrets themselves, but the AWS-side IAM OIDC provider
# and role they point at were set up by hand, so there's nothing to import
# here).
provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = local.aws_default_tags
  }
}

# Same account/region/auth as the default provider, but default_tags adds
# Project = "bedrock-slack-ai-chatbot". default_tags can't be scoped per module,
# so each app that needs its own Project tag gets its own aliased provider,
# passed in through the module's providers argument.
provider "aws" {
  alias  = "bedrock_slack_ai_chatbot"
  region = "ap-northeast-1"
  default_tags {
    tags = local.bedrock_slack_ai_chatbot_default_tags
  }
}

# For module "aws_budget_slack_notifier" in main.tf, which is commented out for
# now. AWS Budgets is a us-east-1 service, so its SNS topic and KMS key live
# there. Uncomment together with that module.
# provider "aws" {
#   alias  = "us-east-1"
#   region = "us-east-1"
# }

# For module "hcp_vault" in main.tf, which is commented out for now. The HVN
# and the peer VPC must share a region, and the module's default is us-west-2.
# Uncomment together with that module.
# provider "aws" {
#   alias  = "us-west-2"
#   region = "us-west-2"
# }
#
# provider "hcp" {}

# For module "google_cloud_hands_on" in main.tf, which is commented out for
# now. Credentials come from the GOOGLE_CREDENTIALS environment variable on the
# works workspace. Uncomment together with that module.
# provider "google" {
#   project = var.google_cloud_hands_on_project_id
#   region  = "asia-northeast1"
# }
