terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# trivy:ignore:AWS-0132
resource "aws_s3_bucket" "gha_custom_action_hosting" {
  bucket = "gha-custom-action-hosting-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# 静的ウェブサイトホスティングの設定
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.gha_custom_action_hosting.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# バケットポリシーを設定してパブリックアクセスを許可
resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.gha_custom_action_hosting.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.gha_custom_action_hosting.arn}/*"
      }
    ]
  })
}

# パブリックアクセスブロックを解除
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.gha_custom_action_hosting.id

  # trivy:ignore:AWS-0086
  block_public_acls = false
  # trivy:ignore:AWS-0087
  block_public_policy = false
  # trivy:ignore:AWS-0091
  ignore_public_acls = false
  # trivy:ignore:AWS-0093
  restrict_public_buckets = false
}
