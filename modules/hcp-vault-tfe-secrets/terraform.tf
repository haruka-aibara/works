terraform {
  required_version = ">= 1.11"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.83"
    }
    # rotation_period and the rest of the automated rotation fields
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.11"
    }
  }
}
