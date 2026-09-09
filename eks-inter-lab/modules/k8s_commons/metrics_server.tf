resource "helm_release" "metrics_server" {
  count            = var.cloud_provider == "aws" ? 1 : 0
  name             = "metrics"
  namespace        = "kube-system"
  create_namespace = true

  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.13.0"

  values = [
    file("${path.module}/values/metrics_server/values.yaml")
  ]
}
