locals {
  istio_gateway_private_values_yaml = <<-YAML
    aws:
      _internal_defaults_do_not_set:
        service:
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-type: nlb
            service.beta.kubernetes.io/aws-load-balancer-scheme: internal
            service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443,4318"
            service.beta.kubernetes.io/aws-load-balancer-ssl-cert: ${var.aws_acm_certificate_arn}
            service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    azure:
      _internal_defaults_do_not_set:
        service:
          annotations:
            service.beta.kubernetes.io/azure-load-balancer-internal: "true"
  YAML

  istio_gateway_public_values_yaml = <<-YAML
    aws:
      _internal_defaults_do_not_set:
        service:
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-type: nlb
            service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
            service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
            service.beta.kubernetes.io/aws-load-balancer-ssl-cert: ${var.aws_acm_certificate_arn}
            service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    azure:
      _internal_defaults_do_not_set:
        service:
          annotations: {}
  YAML

  istio_gateway_private_values = try(
    yamldecode(local.istio_gateway_private_values_yaml)[var.cloud_provider], {}
  )

  istio_gateway_public_values = try(
    yamldecode(local.istio_gateway_public_values_yaml)[var.cloud_provider], {}
  )
}

resource "helm_release" "istio_base" {
  name             = "istio-base"
  namespace        = "istio-system"
  create_namespace = true

  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = "1.26.8"

  values = [
    file("${path.module}/values/istio/base/values.yaml")
  ]
}

resource "helm_release" "istiod" {
  name             = "istiod"
  namespace        = "istio-system"
  create_namespace = true

  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = "1.26.8"

  values = [
    file("${path.module}/values/istio/istiod/values.yaml")
  ]

  depends_on = [
    helm_release.istio_base,
    helm_release.cert_manager
  ]
}

resource "helm_release" "istio_gateway_private" {
  name             = "istio-gateway-private"
  namespace        = "istio-system"
  create_namespace = true

  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = "1.26.8"

  set = [
    {
      name  = "_internal_defaults_do_not_set.podAnnotations.slogger"
      value = "true"
      type  = "string"
    },
    {
      name  = "_internal_defaults_do_not_set.podAnnotations.slogger_index_prefix"
      value = "logs-${var.slogger_environment}-eks-${var.slogger_context}-istio-gateway-private"
    }
  ]

  values = [
    file("${path.module}/values/istio/gateway/private/values.yaml"),
    yamlencode(local.istio_gateway_private_values)
  ]

  depends_on = [
    helm_release.istiod
  ]
}

resource "helm_release" "istio_gateway_public" {
  name             = "istio-gateway-public"
  namespace        = "istio-system"
  create_namespace = true

  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = "1.26.8"

  set = [
    {
      name  = "_internal_defaults_do_not_set.podAnnotations.slogger"
      value = "true"
      type  = "string"
    },
    {
      name  = "_internal_defaults_do_not_set.podAnnotations.slogger_index_prefix"
      value = "logs-${var.slogger_environment}-eks-${var.slogger_context}-istio-gateway-public"
    }
  ]

  values = [
    file("${path.module}/values/istio/gateway/public/values.yaml"),
    yamlencode(local.istio_gateway_public_values)
  ]

  depends_on = [
    helm_release.istiod
  ]
}

resource "kubectl_manifest" "istio_wildcard_cert" {
  count = var.cloud_provider == "azure" ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "wildcard-tls"
      namespace = "istio-system"
    }
    spec = {
      secretName = "wildcard-tls"
      dnsNames = [
        "*.${var.dns_domain}",
        var.dns_domain
      ]
      issuerRef = {
        name = "letsencrypt-wildcard"
        kind = "ClusterIssuer"
      }
    }
  })

  depends_on = [
    helm_release.cert_manager,
    helm_release.istiod,
    kubectl_manifest.letsencrypt_wildcard
  ]
}
