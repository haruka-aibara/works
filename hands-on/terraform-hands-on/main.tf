# ------------------------
# Terraform configuration
# ------------------------
terraform {
  required_version = ">=0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 3.0"
    }
  }
  backend "s3" {
    bucket  = "tastylog-tfstate-bucket-haruharumolly"
    key     = "tastylog-dev.tfstate"
    region  = "ap-northeast-1"
    profile = "default"
  }
}

# ------------------------
# Provider
# ------------------------
provider "aws" {
  profile = "default"
  region  = "ap-northeast-1"
}

provider "aws" {
  alias   = "virginia"
  profile = "default"
  region  = "us-east-1"
}

# ------------------------
# Variables
# ------------------------
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain" {
  type = string
}