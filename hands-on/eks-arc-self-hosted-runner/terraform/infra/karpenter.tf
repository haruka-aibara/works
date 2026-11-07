# Karpenter 本体は Argo CD で入れる。ここでは AWS 側に要るもの（IAM・SQS・EventBridge）だけ作る。
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.26"

  cluster_name = module.eks.cluster_name

  # EC2NodeClass の spec.role に書く名前なので、prefix を付けずに固定する。
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = "${var.name}-karpenter-node"

  create_pod_identity_association = true
}
