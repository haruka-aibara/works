terraform {
  cloud {
    organization = "haruka-aibara"
    workspaces {
      name = "works"
    }
  }

  # The workspace resolves its Terraform version from the terraform_version
  # constraint on tfe_workspace.works, which this configuration itself
  # manages. An exact pin here therefore fails every speculative plan until that
  # upgrade has been applied, so keep a minimum-version constraint instead.
  required_version = ">= 1.15.8"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.81"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.14"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.66.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.8.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}
