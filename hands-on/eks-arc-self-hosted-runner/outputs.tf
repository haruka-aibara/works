output "update_kubeconfig" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.this.name}"
}

output "runs_on" {
  value = helm_release.arc_runner_set.name
}
