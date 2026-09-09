locals {
  external_dns_values_yaml = <<-YAML
    aws:
      serviceAccount:
        annotations:
          eks.amazonaws.com/role-arn: ${var.external_dns_identifier}

    azure:
      serviceAccount:
        annotations:
          azure.workload.identity/client-id: ${var.external_dns_identifier}

      podLabels:
        azure.workload.identity/use: "true"

      extraVolumes:
        - name: azure-config-file
          secret:
            secretName: external-dns-azure

      extraVolumeMounts:
        - name: azure-config-file
          mountPath: /etc/kubernetes
          readOnly: true
  YAML

  external_dns_provider_values = try(
    yamldecode(local.external_dns_values_yaml)[var.cloud_provider], {}
  )
}

resource "kubernetes_secret_v1" "external_dns_azure" {
  count = var.cloud_provider == "azure" ? 1 : 0

  metadata {
    name      = "external-dns-azure"
    namespace = kubernetes_namespace_v1.external_dns.id
  }

  data = {
    "azure.json" = jsonencode({
      tenantId                     = var.azure_tenant_id
      subscriptionId               = var.azure_subscription_id
      resourceGroup                = var.azure_resource_group_name
      useWorkloadIdentityExtension = true
    })
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace_v1.external_dns
  ]
}

resource "helm_release" "external_dns" {
  name      = "external-dns"
  namespace = kubernetes_namespace_v1.external_dns.id

  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.19.0"

  set = [
    {
      name  = "provider.name"
      value = var.cloud_provider
    },
    {
      name  = "domainFilters[0]"
      value = var.dns_domain
    },
    {
      name  = "txtOwnerId"
      value = var.cluster_name
    }
  ]

  values = [
    file("${path.module}/values/external_dns/values.yaml"),
    yamlencode(local.external_dns_provider_values)
  ]

  depends_on = [
    helm_release.azure_workload_identify_system,
    kubernetes_secret_v1.external_dns_azure
  ]
}
