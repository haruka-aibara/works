terraform {
  # Child module of the works monorepo: backend and provider config live in the
  # root module (../../terraform.tf, ../../providers.tf) only. This block just
  # states what this module itself needs.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.19.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.8.0"
    }
  }
}
