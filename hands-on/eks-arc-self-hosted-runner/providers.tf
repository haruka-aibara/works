provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = var.name
    }
  }
}

# クラスタと同じ apply で Helm chart を入れるため、接続情報は aws_eks_cluster から取る。
# 認証は apply する人の AWS 認証情報で aws eks get-token する（クラスタ作成者は admin になる）。
provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.this.name, "--region", var.region]
    }
  }
}
