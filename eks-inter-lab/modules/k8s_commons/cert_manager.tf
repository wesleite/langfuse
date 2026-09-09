locals {
  cert_manager_values_yaml = <<-YAML
    aws: {}

    azure:
      serviceAccount:
        annotations:
          azure.workload.identity/client-id: ${var.cert_manager_identifier}

      podLabels:
        azure.workload.identity/use: "true"
  YAML

  cert_manager_dns_providers_yaml = <<-YAML
    aws: []

    azure:
      - dns01:
          azureDNS:
            managedIdentity:
              clientID: ${var.cert_manager_identifier}
            subscriptionID: ${var.azure_subscription_id}
            resourceGroupName: ${var.azure_resource_group_name}
            hostedZoneName: ${var.dns_domain}
            environment: AzurePublicCloud
  YAML

  cert_manager_provider_values = try(
    yamldecode(local.cert_manager_values_yaml)[var.cloud_provider], {}
  )

  cert_manager_dns_solvers = try(
    yamldecode(local.cert_manager_dns_providers_yaml)[var.cloud_provider], []
  )
}

resource "helm_release" "cert_manager" {
  count     = var.cloud_provider == "azure" ? 1 : 0
  name      = "cert-manager"
  namespace = kubernetes_namespace_v1.cert_manager[0].id

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.19.3"

  values = [
    file("${path.module}/values/cert_manager/values.yaml"),
    yamlencode(local.cert_manager_provider_values)
  ]

  depends_on = [
    helm_release.azure_workload_identify_system,
    kubernetes_namespace_v1.cert_manager
  ]
}

resource "kubectl_manifest" "letsencrypt_wildcard" {
  count = var.cloud_provider == "azure" ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-wildcard"
    }
    spec = {
      acme = {
        email               = "devops@solides.com.br"
        server              = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = { name = "letsencrypt-wildcard-key" }
        solvers             = local.cert_manager_dns_solvers
      }
    }
  })

  depends_on = [
    helm_release.cert_manager
  ]
}
