{{/* 全 Application 共通の syncPolicy。CRD を別の Application が入れるので、揃うまでリトライさせる。 */}}
{{- define "apps.syncPolicy" -}}
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  syncOptions:
    - CreateNamespace=true
    - ServerSideApply=true
  retry:
    limit: 10
    backoff:
      duration: 30s
      factor: 2
      maxDuration: 5m
{{- end }}
