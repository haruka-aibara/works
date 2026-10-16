# クラスタを作る infra と、クラスタに Argo CD を入れる bootstrap は apply を分ける。
# 同じ apply にすると、クラスタができる前に Helm provider の接続先を決められないため。
data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../infra/terraform.tfstate"
  }
}

locals {
  infra = data.terraform_remote_state.infra.outputs
}

data "aws_eks_cluster" "this" {
  name = local.infra.cluster_name
}
