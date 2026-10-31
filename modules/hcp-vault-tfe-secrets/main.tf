# =========================================
# HCP Terraform secrets engine on HCP Vault, with a team token as its root
# =========================================
# Vault holds a token of its own team and rotates it itself (rotate-root, and
# rotation_period through the Enterprise Rotation Manager). Both need Vault
# 2.2.0+. The bootstrap is in docs/runbooks/hcp-vault-tfe-secrets.md.

# A team other than owners needs a paid plan.
# manage_teams lets the team's own token create and delete the team's tokens,
# which is all rotate-root does.
resource "tfe_team" "vault" {
  name         = "vault-root"
  organization = var.organization
  visibility   = "organization"

  organization_access {
    manage_teams = true
  }
}

resource "vault_terraform_cloud_secret_backend" "this" {
  count = var.configure_secrets_engine ? 1 : 0

  backend = "terraform"

  # Sent on create and when token_wo_version changes, never otherwise, so an
  # apply after Vault has rotated does not put the dead bootstrap token back.
  token_wo         = var.bootstrap_team_token
  token_wo_version = 1

  rotation_period = var.rotation_period
}
