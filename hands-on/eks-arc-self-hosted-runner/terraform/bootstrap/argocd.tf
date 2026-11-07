# Terraform が入れるのは Argo CD と root Application まで。
# それ以外（Karpenter・ESO・ARC）は root Application が gitops/apps から入れる。
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.9.2"

  values = [yamlencode({
    # UI は kubectl port-forward で見るので、SSO（Dex）と通知は入れない。
    dex           = { enabled = false }
    notifications = { enabled = false }

    configs = {
      # OCI の Helm chart を Application から参照するための登録。
      repositories = {
        karpenter = {
          name      = "karpenter"
          type      = "helm"
          url       = "public.ecr.aws/karpenter"
          enableOCI = "true"
        }
        arc = {
          name      = "actions-runner-controller"
          type      = "helm"
          url       = "ghcr.io/actions/actions-runner-controller-charts"
          enableOCI = "true"
        }
      }
    }
  })]
}

resource "helm_release" "root_app" {
  name       = "root-app"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.5"

  values = [yamlencode({
    applications = {
      # finalizer を付けないので、root を消しても配下の Application は残る。
      # 片付けの順番を README の手順で制御するため。
      root = {
        namespace = "argocd"
        project   = "default"
        source = {
          repoURL        = var.gitops_repo_url
          targetRevision = var.gitops_revision
          path           = "hands-on/eks-arc-self-hosted-runner/gitops/apps"
          helm = {
            valuesObject = {
              gitops = {
                repoURL        = var.gitops_repo_url
                targetRevision = var.gitops_revision
              }
              region      = local.infra.region
              clusterName = local.infra.cluster_name
              karpenter = {
                interruptionQueue = local.infra.karpenter_queue_name
                nodeRoleName      = local.infra.karpenter_node_role_name
              }
              github = {
                configUrl     = var.github_config_url
                appSecretName = local.infra.github_app_secret_name
              }
              maxRunners = var.max_runners
            }
          }
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
        }
      }
    }
  })]

  depends_on = [helm_release.argocd]
}
