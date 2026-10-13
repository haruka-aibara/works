terraform {
  # Provider config lives in the root module (../../providers.tf) only.
  # This block just states what this module itself needs.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.68.0"
    }
  }
}
