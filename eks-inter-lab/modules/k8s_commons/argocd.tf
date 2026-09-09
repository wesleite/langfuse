resource "kubernetes_secret_v1" "argocd_dex_google_sso" {
  count = var.cloud_provider == "aws" && var.argocd_enabled ? 1 : 0

  metadata {
    name      = "argocd-dex-google-sso-secret"
    namespace = "cicd"
    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    clientID     = var.argocd_dex_google_sso_client_id
    clientSecret = var.argocd_dex_google_sso_client_secret
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace_v1.cicd
  ]
}

resource "helm_release" "argocd" {
  count            = var.cloud_provider == "aws" && var.argocd_enabled ? 1 : 0
  name             = "argocd"
  namespace        = "cicd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.0.13"

  set = [
    {
      name  = "global.domain"
      value = "argocd.${var.dns_domain}"
    },
    {
      name  = "configs.credentialTemplates.azure.password"
      value = var.argocd_azure_password
    },
    {
      name  = "configs.credentialTemplates.gitlab.password"
      value = var.argocd_gitlab_password
    }
  ]

  values = [
    file("${path.module}/values/argocd/values.yaml")
  ]

  depends_on = [
    kubernetes_secret_v1.argocd_dex_google_sso,
    helm_release.istio_gateway_private,
    helm_release.external_dns,
  ]
}

resource "kubectl_manifest" "argocd_istio_gateway" {
  count = var.cloud_provider == "aws" && var.argocd_enabled ? 1 : 0

  yaml_body = templatefile("${path.module}/values/argocd/istio_gateway.tpl.yaml", {
    host = "argocd.${var.dns_domain}"
  })

  depends_on = [
    helm_release.argocd
  ]
}

resource "kubectl_manifest" "argocd_istio_virtualservice" {
  count = var.cloud_provider == "aws" && var.argocd_enabled ? 1 : 0

  yaml_body = templatefile("${path.module}/values/argocd/istio_virtualservice.tpl.yaml", {
    host = "argocd.${var.dns_domain}"
  })

  depends_on = [
    kubectl_manifest.argocd_istio_gateway
  ]
}
