locals {
  kube_prometheus_stack_values_yaml = <<-YAML
    aws:
      prometheus:
        serviceAccount:
          annotations:
            eks.amazonaws.com/role-arn: ${var.prometheus_aws_iam_role_arn}

    azure:
      prometheus:
        serviceAccount:
          annotations:
            eks.amazonaws.com/role-arn: ${var.prometheus_aws_iam_role_arn}
  YAML

  kube_prometheus_stack_values = try(
    yamldecode(local.kube_prometheus_stack_values_yaml)[var.cloud_provider], {}
  )
}

resource "kubernetes_secret_v1" "thanos_sidecar_object_storage" {
  count = var.prometheus_enabled ? 1 : 0

  metadata {
    name      = "thanos-sidecar-objstore-secret"
    namespace = kubernetes_namespace_v1.monitoring.id
  }

  type = "Opaque"

  data = {
    "objstore.yml" = <<EOF
type: S3
config:
  bucket: thanos-monitoring-infrastructure
  endpoint: s3.amazonaws.com
  region: us-east-1
EOF
  }

  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]
}

resource "helm_release" "kube_prometheus_stack" {
  count     = var.prometheus_enabled ? 1 : 0
  name      = "kube-prometheus-stack"
  namespace = kubernetes_namespace_v1.monitoring.id

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "75.6.1"

  set = [
    {
      name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
      value = var.prometheus_disk_size_gb
    },
    {
      name  = "prometheus.prometheusSpec.externalLabels.cluster"
      value = var.cluster_name
    }
  ]

  values = [
    file("${path.module}/values/kube_prometheus_stack/values.yaml"),
    yamlencode(local.kube_prometheus_stack_values)
  ]

  depends_on = [
    helm_release.istio_gateway_private,
    helm_release.external_dns,
    kubernetes_secret_v1.thanos_sidecar_object_storage
  ]
}

resource "kubectl_manifest" "kube_prometheus_stack_istio_gateway" {
  count = var.prometheus_enabled ? 1 : 0

  yaml_body = templatefile("${path.module}/values/kube_prometheus_stack/istio_gateway.tpl.yaml", {
    dns_domain     = var.dns_domain
    cloud_provider = var.cloud_provider
  })

  depends_on = [
    helm_release.kube_prometheus_stack
  ]
}

resource "kubectl_manifest" "kube_prometheus_stack_istio_virtualservice" {
  count = var.prometheus_enabled ? 1 : 0

  yaml_body = templatefile("${path.module}/values/kube_prometheus_stack/istio_virtualservice.tpl.yaml", {
    dns_domain = var.dns_domain
  })

  depends_on = [
    kubectl_manifest.kube_prometheus_stack_istio_gateway
  ]
}
