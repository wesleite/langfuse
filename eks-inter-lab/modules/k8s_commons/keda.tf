resource "helm_release" "keda" {
  name             = "keda"
  namespace        = "kube-system"
  create_namespace = true

  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = "2.17.2"

  values = [
    file("${path.module}/values/keda/values.yaml")
  ]
}
