output "region" {
  value = var.region
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "karpenter_queue_name" {
  value = module.karpenter.queue_name
}

output "karpenter_node_role_name" {
  value = module.karpenter.node_iam_role_name
}

output "github_app_secret_name" {
  value = data.aws_secretsmanager_secret.github_app.name
}

output "update_kubeconfig" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
