output "vault_public_endpoint_url" {
  value = hcp_vault_cluster.learn_hcp_vault.vault_public_endpoint_url
}

output "vault_version" {
  value = hcp_vault_cluster.learn_hcp_vault.vault_version
}

output "admin_token" {
  value     = hcp_vault_cluster_admin_token.this.token
  sensitive = true
}
