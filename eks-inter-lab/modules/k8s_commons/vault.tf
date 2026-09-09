resource "helm_release" "vault" {
  count            = var.vault_enabled ? 1 : 0
  name             = "vault"
  namespace        = "vault"
  create_namespace = true

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.30.1"

  values = [
    templatefile("${path.module}/values/vault/values.tpl.yaml", {
      cloud_provider               = var.cloud_provider
      vault_identifier             = var.vault_identifier
      vault_node_isolation_enabled = var.vault_node_isolation_enabled
      awskms_seal = var.cloud_provider == "aws" && var.vault_aws_kms_key_arn != "" ? templatefile("${path.module}/values/vault/awskms_seal.tpl", {
        kms_key_arn = var.vault_aws_kms_key_arn
      }) : ""
    })
  ]

  depends_on = [
    helm_release.istio_gateway_private,
    helm_release.external_dns,
    helm_release.aws_load_balancer_controller
  ]
}

resource "helm_release" "vault_secrets_webhook" {
  count            = var.vault_enabled ? 1 : 0
  name             = "vault-secrets-webhook"
  namespace        = "vault"
  create_namespace = true

  repository = "oci://ghcr.io/bank-vaults/helm-charts"
  chart      = "vault-secrets-webhook"
  version    = "1.22.1"

  values = [
    file("${path.module}/values/vault_secrets_webhook/values.yaml")
  ]

  depends_on = [
    helm_release.istio_gateway_private,
    helm_release.external_dns,
    helm_release.aws_load_balancer_controller,
    helm_release.vault
  ]
}

resource "kubectl_manifest" "vault_istio_gateway" {
  count = var.vault_enabled ? 1 : 0
  yaml_body = templatefile("${path.module}/values/vault/istio_gateway.tpl.yaml", {
    dns_domain     = var.dns_domain
    cloud_provider = var.cloud_provider
  })

  depends_on = [
    helm_release.vault
  ]
}

resource "kubectl_manifest" "vault_istio_virtualservice" {
  count = var.vault_enabled ? 1 : 0
  yaml_body = templatefile("${path.module}/values/vault/istio_virtualservice.tpl.yaml", {
    dns_domain = var.dns_domain
  })

  depends_on = [
    kubectl_manifest.vault_istio_gateway
  ]
}