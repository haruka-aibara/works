# =========================================
# for personal use only
# =========================================

# Terraform meta repository (monorepo)
# Renamed from "haruka-aibara" and transferred to the organization. The old
# owner/name combination is retired by GitHub and cannot be reused.
module "haruka-aibara" {
  source = "./modules/repository"

  repository_name = "works"
  description     = "Personal monorepo: Terraform for GitHub repos, HCP Terraform and AWS (Slack/Bedrock bots etc.), shared CI, 1000+ learning notes on GitHub Pages, and devcontainer templates"
  homepage_url    = "https://haruka-aibara.github.io/works/"

  topics = ["terraform", "github", "iac", "aws", "github-actions", "devcontainer"]

  # docs/ absorbed the old standalone "docs" repository, .nojekyll included, so
  # Pages now publishes straight from this branch/folder instead of a separate repo.
  pages = {
    branch = "main"
    path   = "/docs"
  }

  # main is auto-applied, so a red PR must not be mergeable -- not even by an
  # admin. If a check itself is broken, lift this in the UI; the next apply
  # puts it back.
  enforce_admins         = true
  required_status_checks = local.works_required_status_checks
}

# =========================================
# My Slack AI Integration Projects
# =========================================

# DevelopersIO Article Summarizer — infrastructure.
# Absorbed from the standalone generate-dev-io-summary repository with its
# history (git log -- modules/generate-dev-io-summary). Not needed right now,
# so the call is commented out. To enable it, uncomment this block and the
# generate_dev_io_summary_* variables in variables.tf, then set the variables
# on the works workspace.
# module "generate_dev_io_summary" {
#   source = "./modules/generate-dev-io-summary"
#
#   slack_channel_id   = var.generate_dev_io_summary_slack_channel_id
#   slack_workspace_id = var.generate_dev_io_summary_slack_workspace_id
# }

# Thread-aware Bedrock Chatbot — application infrastructure.
# Absorbed from the standalone bedrock-slack-ai-chatbot repository/workspace;
# see docs/runbooks/bedrock-slack-ai-chatbot-state-merge.md for the migration.
module "bedrock_slack_ai_chatbot_infra" {
  source = "./modules/bedrock-slack-ai-chatbot"
  providers = {
    aws = aws.bedrock_slack_ai_chatbot
  }

  slack_bot_token      = var.bedrock_slack_ai_chatbot_slack_bot_token
  slack_signing_secret = var.bedrock_slack_ai_chatbot_slack_signing_secret
}

# Multi-turn Bedrock AI Agent — infrastructure.
# Absorbed from the standalone bedrock-slack-ai-agent repository with its
# history (git log -- modules/bedrock-agent-classic-slack). Built on Amazon
# Bedrock Agents, which became "Bedrock Agents Classic" and entered maintenance
# mode on 2026-07-30 (closed to new customers, no new features or models), so
# the call is commented out. To enable it, uncomment this block and the
# bedrock_agent_slack_* variables in variables.tf, then set the variables on
# the works workspace.
# module "bedrock_agent_classic_slack" {
#   source = "./modules/bedrock-agent-classic-slack"
#
#   slack_team_id    = var.bedrock_agent_slack_team_id
#   slack_channel_id = var.bedrock_agent_slack_channel_id
# }

# =========================================
# My AWS Projects
# =========================================

# AWS Budget Slack Notifications — infrastructure.
# Absorbed from the standalone terraform-aws-budget-slack-notifier repository
# with its history (git log -- modules/aws-budget-slack-notifier). Not needed
# right now, so the call is commented out. To enable it, uncomment this block,
# the aws.us-east-1 provider in providers.tf and the budget_* variables in
# variables.tf, then set the variables on the works workspace.
# module "aws_budget_slack_notifier" {
#   source = "./modules/aws-budget-slack-notifier"
#
#   providers = {
#     aws           = aws
#     aws.us-east-1 = aws.us-east-1
#   }
#
#   slack_channel_id           = var.budget_slack_channel_id
#   slack_workspace_id         = var.budget_slack_workspace_id
#   budgets_limit_amount_daily = var.budget_limit_amount_daily
# }

# AWS Cost Allocation Tags — infrastructure.
# Absorbed from the standalone aws-cost-allocation-tags repository with its
# history (git log -- modules/aws-cost-allocation-tags). Not needed right now,
# so the call is commented out. To enable it, uncomment this block.
# module "aws_cost_allocation_tags" {
#   source = "./modules/aws-cost-allocation-tags"
# }

# =========================================
# My AWS Learning Repositories
# =========================================

# AWS Config rules backed by Cloud Custodian — infrastructure.
# Each YAML file under modules/aws-config-custodian/policies becomes one Config
# rule. The module also creates the region's Config recorder, recording only a
# resource type the account doesn't have so it records (and bills) nothing.
# Tried once; not needed right now, so the call is commented out (see
# ideas/2026-09-26-Cloud_CustodianでConfigルールを作ってみた.md). To enable
# it, uncomment this block.
# module "aws_config_custodian" {
#   source = "./modules/aws-config-custodian"
# }

# IAM Access Analyzer Policy Generate — infrastructure.
# Absorbed from the standalone iam-access-analyzer-policy-generate repository
# with its history (git log -- modules/iam-access-analyzer-policy-generate).
# Not needed right now, so the call is commented out. To enable it, uncomment
# this block.
# module "iam_access_analyzer_policy_generate" {
#   source = "./modules/iam-access-analyzer-policy-generate"
# }

# =========================================
# My HCP Vault Learning Repositories
# =========================================

# HCP Vault Dedicated — infrastructure.
# Absorbed from the standalone deploy-hcp-vault-dedicated-with-terraform
# repository with its history (git log -- modules/hcp-vault). Not needed right
# now, so the call is commented out. To enable it, uncomment this block and the
# aws.us-west-2 / hcp providers in providers.tf, add hashicorp/hcp to
# required_providers in terraform.tf, then set HCP_CLIENT_ID /
# HCP_CLIENT_SECRET on the works workspace.
# module "hcp_vault" {
#   source = "./modules/hcp-vault"
#
#   providers = {
#     aws = aws.us-west-2
#   }
# }

# =========================================
# My Google Cloud Learning Repositories
# =========================================

# Google Cloud Hands-on — infrastructure (budget alert).
# Absorbed from the standalone google-cloud-hands-on repository with its
# history (git log -- modules/google-cloud-hands-on). Not needed right now, so
# the call is commented out. To enable it, uncomment this block, the google
# provider in providers.tf and the google_cloud_hands_on_* variables in
# variables.tf, add hashicorp/google to required_providers in terraform.tf,
# then set GOOGLE_CREDENTIALS and the variables on the works workspace.
# module "google_cloud_hands_on" {
#   source = "./modules/google-cloud-hands-on"
#
#   project_id         = var.google_cloud_hands_on_project_id
#   billing_account_id = var.google_cloud_hands_on_billing_account_id
# }

# =========================================
# CI
# =========================================

# CI used to be distributed from workflow-dist/ as github_repository_file. It now
# lives directly in .github/workflows/, so stop managing the files without
# deleting them from the repository. Delete these blocks after one apply.
removed {
  from = github_repository_file.terraform_ci_caller

  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_file.python_ci_caller

  lifecycle {
    destroy = false
  }
}

# =========================================
# HCP Terraform
# =========================================

# The VCS connection is an organization-level OAuth client, not the GitHub App
# HCP Terraform offers by default. The App ties "may this caller connect that
# repository" to a person's GitHub account, which no API token this
# configuration can issue for itself ever has -- see
# docs/reference/github-authentication.md for why that ruled the App out.
#
# vcs_repo wants the OAuth *token* id (ot-...), which belongs to the client
# (oc-...). Look it up rather than storing it: re-authorizing the connection
# mints a new token id, and this way that costs no edit here.
data "tfe_oauth_client" "this" {
  organization     = local.tfe_organization
  service_provider = "github"
}

# Haruka Aibara Workspace
resource "tfe_workspace" "works" {
  name                          = "works"
  organization                  = local.tfe_organization
  description                   = "Terraform-managed GitHub repositories, HCP Terraform workspaces, and AWS resources"
  auto_apply                    = true
  auto_apply_run_trigger        = false
  file_triggers_enabled         = false
  queue_all_runs                = false
  structured_run_output_enabled = false
  terraform_version             = "~> 1.16.0"

  vcs_repo {
    identifier         = "${local.github_owner}/works"
    oauth_token_id     = local.oauth_token_id
    ingress_submodules = false
  }
}

# =========================================
# Workspace variables (works)
# =========================================
# The github provider reads GitHub App credentials from GITHUB_APP_* environment
# variables, so switching away from a PAT needs no provider block change.
#
# What these credentials are, and why the setup looks like this:
# docs/reference/github-authentication.md
#
# Terraform declares these variables; the UI holds their values. The placeholder
# below is written once, at creation, and is then left alone: HCP Terraform never
# returns a sensitive variable's value, so the provider carries the last known
# state value forward on every read and only ever writes a new one if `value`
# changes here. No ignore_changes is needed for that — it is how the provider
# treats sensitive variables.
#
# The consequence is that Terraform cannot see these values at all. It will not
# detect a key cleared or corrupted in the UI, and a plan stays clean either way.
#
# The private key has to be handled this way, since a value written here would
# land in state. The ids do not — only the private key can sign a token request,
# so neither identifier opens anything on its own — but they take the same shape
# so there is one rule rather than two, and so this public repository names
# nothing about the organization's App.

resource "tfe_variable" "github_app_id" {
  workspace_id = tfe_workspace.works.id
  key          = "GITHUB_APP_ID"
  value        = "set-in-ui"
  category     = "env"
  sensitive    = true
  description  = "GitHub App ID. Set this value in the UI."
}

resource "tfe_variable" "github_app_installation_id" {
  workspace_id = tfe_workspace.works.id
  key          = "GITHUB_APP_INSTALLATION_ID"
  value        = "set-in-ui"
  category     = "env"
  sensitive    = true
  description  = "Installation ID of the GitHub App on the organization. Set this value in the UI."
}

resource "tfe_variable" "github_app_pem_file" {
  workspace_id = tfe_workspace.works.id
  key          = "GITHUB_APP_PEM_FILE"
  value        = "set-in-ui"
  category     = "env"
  sensitive    = true
  description  = "GitHub App private key (PEM). Set this value in the UI."
}

# =========================================
# bedrock-slack-ai-chatbot module credentials
# =========================================
# Same reasoning as the GitHub App variables above: HCP Terraform never
# returns a sensitive variable's value, so these are declared once with a
# placeholder and the real value is set in the UI afterward.
#
# AWS itself is authenticated via dynamic provider credentials (OIDC), not
# static keys -- see providers.tf -- so there is no AWS_ACCESS_KEY_ID /
# AWS_SECRET_ACCESS_KEY here.
#
# ignore_changes on value: these two were created by hand in the UI before
# this code landed, so they were adopted with an `import` block rather than
# created fresh. HCP Terraform never returns a sensitive value, so after
# import the provider has no way to know it already
# matches "set-in-ui" and would otherwise plan to overwrite the real secret
# with the placeholder. ignore_changes makes that impossible, since neither
# is meant to be written from code again after their first value is set in
# the UI.

resource "tfe_variable" "bedrock_slack_ai_chatbot_slack_bot_token" {
  workspace_id = tfe_workspace.works.id
  key          = "bedrock_slack_ai_chatbot_slack_bot_token"
  value        = "set-in-ui"
  category     = "terraform"
  sensitive    = true
  description  = "Slack Bot User OAuth Token for the bedrock-slack-ai-chatbot module. Set this value in the UI."

  lifecycle {
    ignore_changes = [value]
  }
}

resource "tfe_variable" "bedrock_slack_ai_chatbot_slack_signing_secret" {
  workspace_id = tfe_workspace.works.id
  key          = "bedrock_slack_ai_chatbot_slack_signing_secret"
  value        = "set-in-ui"
  category     = "terraform"
  sensitive    = true
  description  = "Slack Signing Secret for the bedrock-slack-ai-chatbot module. Set this value in the UI."

  lifecycle {
    ignore_changes = [value]
  }
}

# =========================================
# TFE_TOKEN rotation
# =========================================

# TFE_TOKEN self-rotation (blue / green). The how and why are in the module and
# docs/runbooks/tfe-token-rotation.md.
module "tfe_team_token_rotation" {
  source = "./modules/tfe-team-token-rotation"

  organization = local.tfe_organization
  workspace_id = tfe_workspace.works.id

  rotation_minutes = var.rotation_minutes
  buffer_minutes   = var.buffer_minutes

  # Bump one to rotate that colour now -- only ever the one NOT in use.
  blue_serial  = 1
  green_serial = 1
}
