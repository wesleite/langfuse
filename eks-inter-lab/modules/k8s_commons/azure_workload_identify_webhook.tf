resource "helm_release" "azure_workload_identify_system" {
  count            = var.cloud_provider == "azure" ? 1 : 0
  name             = "workload-identity-webhook"
  namespace        = "azure-workload-identity-system"
  create_namespace = true

  repository = "https://azure.github.io/azure-workload-identity/charts"
  chart      = "workload-identity-webhook"
  version    = "1.5.1"

  set = [
    {
      name  = "azureTenantID"
      value = var.azure_tenant_id
    }
  ]

  values = [
    file("${path.module}/values/azure_workload_identify_webhook/values.yaml")
  ]
}
