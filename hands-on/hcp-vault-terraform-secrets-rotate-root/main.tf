# =========================================
# HCP Vault Dedicated
# =========================================

resource "hcp_hvn" "this" {
  hvn_id         = "rotate-root-hvn"
  cloud_provider = "aws"
  region         = "us-west-2"
  cidr_block     = "172.25.16.0/20"
}

# 自動ローテーション（Rotation Manager）は Enterprise 機能で、
# terraform secrets engine 側の対応は Vault 2.2.0 から。
# 立ったら output の vault_version を確認する。
resource "hcp_vault_cluster" "this" {
  cluster_id      = "rotate-root"
  hvn_id          = hcp_hvn.this.hvn_id
  tier            = "dev"
  public_endpoint = true
}

resource "hcp_vault_cluster_admin_token" "this" {
  cluster_id = hcp_vault_cluster.this.cluster_id
}

# =========================================
# HCP Terraform（有料プランでないと owners 以外の team を作れない）
# =========================================

# Vault が root token として持つ team。
# 自分の team token の作成・削除と、role 用の他 team の token 発行のために manage_teams を付ける。
resource "tfe_team" "vault" {
  name       = "vault-root"
  visibility = "organization"

  organization_access {
    manage_teams = true
  }
}

# =========================================
# Vault: HCP Terraform secrets engine
# =========================================

resource "vault_terraform_cloud_secret_backend" "this" {
  backend = "terraform"

  # 最初の 1 回だけ書き込まれる。以降の apply では送られないので、
  # Vault が回したトークンを古い値で上書きしない。
  token_wo         = var.bootstrap_team_token
  token_wo_version = 1

  rotation_period = var.rotation_period
}

output "vault_url" {
  value = hcp_vault_cluster.this.vault_public_endpoint_url
}

output "vault_version" {
  value = hcp_vault_cluster.this.vault_version
}

output "team_id" {
  value = tfe_team.vault.id
}
