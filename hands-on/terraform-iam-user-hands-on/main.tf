# ---------------------------------------------
# Terraform configuration
# ---------------------------------------------
terraform {
  required_version = ">=0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.19"
    }
  }
  backend "s3" {
    bucket  = "tastylog-tfstate-bucket-haruharumolly"
    key     = "tastylog-user.tfstate"
    region  = "ap-northeast-1"
    profile = "default"
  }
}

# ---------------------------------------------
# Provider
# ---------------------------------------------
provider "aws" {
  profile = "default"
  region  = "ap-northeast-1"
}

# ---------------------------------------------
# Variables
# ---------------------------------------------
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "user_name" {
  type = string
}