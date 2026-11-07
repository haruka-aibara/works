variable "hvn_id" {
  description = "The ID of the HCP HVN."
  type        = string
  default     = "learn-hcp-vault-hvn"
}

variable "cluster_id" {
  description = "The ID of the HCP Vault cluster."
  type        = string
  default     = "learn-hcp-vault-cluster"
}

variable "peering_id" {
  description = "The ID of the HCP peering connection."
  type        = string
  default     = "learn-peering"
}

variable "route_id" {
  description = "The ID of the HCP HVN route."
  type        = string
  default     = "learn-hvn-route"
}

variable "region" {
  description = "The region of the HCP HVN and Vault cluster."
  type        = string
  default     = "us-west-2"
}

variable "cloud_provider" {
  description = "The cloud provider of the HCP HVN and Vault cluster."
  type        = string
  default     = "aws"
}

variable "tier" {
  description = "Tier of the HCP Vault cluster. Valid options for tiers."
  type        = string
  default     = "dev"
}

variable "vpc_peering" {
  description = "Whether to create the peer VPC on AWS and peer it with the HVN. Clients that reach the cluster only through its public endpoint don't need it."
  type        = bool
  default     = true
}
