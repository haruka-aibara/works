data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)
}

# 数日で消す前提なので、NAT Gateway は AZ ごとではなく 1 個にしている。
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name = var.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for i, _ in local.azs : cidrsubnet(local.vpc_cidr, 4, i)]
  public_subnets  = [for i, _ in local.azs : cidrsubnet(local.vpc_cidr, 8, i + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  private_subnet_tags = {
    "karpenter.sh/discovery" = var.name
  }
}

# trivy の指摘のうち、この構成で必要なものを見送る。
# AWS-0040: 手元から kubectl / helm を使うため public endpoint を開ける（アクセス元は endpoint_public_access_cidrs で絞る）
# AWS-0104: ノードはイメージの pull や GitHub との通信で外に出るので、egress は絞らない
#trivy:ignore:AWS-0040
#trivy:ignore:AWS-0104
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.26"

  name = var.name

  # 消し忘れても延長サポート（$0.60/h）に入らず、標準サポート終了時に自動で上がる。
  upgrade_policy = {
    support_type = "STANDARD"
  }

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  # ノードや Pod は private endpoint を使う。public 側は kubectl / helm を使う手元の IP だけ許す。
  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.api_allowed_cidrs

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  # Argo CD・Karpenter・ESO・ARC の controller が常駐するノード。
  # runner はここには載せず、Karpenter がジョブのたびに別のノードを立てる。
  eks_managed_node_groups = {
    system = {
      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.medium"]

      min_size     = 1
      max_size     = 1
      desired_size = 1

      labels = {
        "karpenter.sh/controller" = "true"
      }
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.name
  }
}
