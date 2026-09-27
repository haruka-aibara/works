locals {
  arc_chart_repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
}

resource "helm_release" "arc_controller" {
  name             = "arc"
  namespace        = "arc-systems"
  create_namespace = true
  repository       = local.arc_chart_repository
  chart            = "gha-runner-scale-set-controller"
  version          = var.arc_chart_version

  depends_on = [aws_eks_node_group.this]
}

# destroy 時は runner の後片付けを controller がするので、こちらが先に消える順序にしておく。
resource "helm_release" "arc_runner_set" {
  name             = var.runner_scale_set_name
  namespace        = "arc-runners"
  create_namespace = true
  repository       = local.arc_chart_repository
  chart            = "gha-runner-scale-set"
  version          = var.arc_chart_version

  values = [yamlencode({
    githubConfigUrl = var.github_config_url
    minRunners      = 0
    maxRunners      = var.max_runners
  })]

  set_sensitive = [{
    name  = "githubConfigSecret.github_token"
    value = var.github_token
  }]

  depends_on = [helm_release.arc_controller]
}
