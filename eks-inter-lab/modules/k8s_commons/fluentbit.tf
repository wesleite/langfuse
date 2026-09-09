resource "kubernetes_secret_v1" "fluentbit_elastic" {
  metadata {
    name      = "fluentbit-elastic"
    namespace = "logs"
  }

  data = {
    user     = var.fluentbit_elastic_user
    password = var.fluentbit_elastic_password
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace_v1.logs
  ]
}

resource "helm_release" "fluentbit_collector" {
  name      = "fluentbit-collector"
  namespace = "logs"

  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.49.1"

  values = [
    file("${path.module}/values/fluentbit_collector/values.yaml")
  ]

  depends_on = [
    kubernetes_secret_v1.fluentbit_elastic
  ]
}

resource "helm_release" "fluentbit_gateway" {
  name             = "fluentbit-gateway"
  namespace        = "logs"
  create_namespace = true

  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.49.1"

  values = [
    file("${path.module}/values/fluentbit_gateway/values.yaml")
  ]

  depends_on = [
    kubernetes_secret_v1.fluentbit_elastic
  ]
}
