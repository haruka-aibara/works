resource "hcp_hvn" "learn_hcp_vault_hvn" {
  hvn_id         = var.hvn_id
  cloud_provider = var.cloud_provider
  region         = var.region
}

resource "hcp_vault_cluster" "learn_hcp_vault" {
  hvn_id          = hcp_hvn.learn_hcp_vault_hvn.hvn_id
  cluster_id      = var.cluster_id
  tier            = var.tier
  public_endpoint = true
}

# For the root vault provider. The token lasts 6 hours; the hcp provider issues a
# new one on the first refresh after that, so every plan gets a live one.
resource "hcp_vault_cluster_admin_token" "this" {
  cluster_id = hcp_vault_cluster.learn_hcp_vault.cluster_id
}
