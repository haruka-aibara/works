terraform {
  # Provider config lives in the root module (../../providers.tf) only.
  # This block just states what this module itself needs.
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.82"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.14"
    }
  }
}
