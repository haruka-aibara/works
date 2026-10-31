# works ワークスペースとは別に、手元で apply する（state はローカル）。
terraform {
  required_version = ">= 1.11"

  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.115"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.83"
    }
    # rotation_period などを持つのは 5.11.0 から
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.11"
    }
  }
}

# HCP_CLIENT_ID / HCP_CLIENT_SECRET を環境変数で渡す
provider "hcp" {}

# TFE_TOKEN を環境変数で渡す（team を作れる権限のトークン）
provider "tfe" {
  organization = var.tfe_organization
}

provider "vault" {
  address   = hcp_vault_cluster.this.vault_public_endpoint_url
  token     = hcp_vault_cluster_admin_token.this.token
  namespace = "admin"
}
