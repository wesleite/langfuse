locals {
  otel_env = [
    {
      name  = "OTEL_RESOURCE_ATTRIBUTES"
      value = "deployment.environment=${var.environment},k8s.cluster.name=${var.cluster_name}"
    },
    {
      name = "OTEL_SERVICE_NAME"
      valueFrom = {
        fieldRef = {
          fieldPath = "metadata.labels['app.kubernetes.io/name']"
        }
      }
    }
  ]
}

resource "helm_release" "opentelemetry_operator" {
  name             = "opentelemetry-operator"
  namespace        = kubernetes_namespace_v1.monitoring.id
  create_namespace = true

  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-operator"
  version    = "0.113.1"

  values = [
    file("${path.module}/values/opentelemetry_operator/values.yaml")
  ]
}

resource "kubectl_manifest" "otel_instrumentation" {
  yaml_body = yamlencode({
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "Instrumentation"

    metadata = {
      name      = "instrumentation"
      namespace = "monitoring"
    }

    spec = {
      exporter = {
        endpoint = "https://otel-collector.infrastructure.solides.com.br:4318"
      }

      propagators = ["tracecontext", "baggage"]

      sampler = {
        type     = "parentbased_traceidratio"
        argument = "0.1"
      }

      nodejs = {
        env = local.otel_env
      }

      java = {
        env = local.otel_env
      }

      python = {
        env = local.otel_env
      }

      dotnet = {
        env = local.otel_env
      }

      go = {
        env = local.otel_env
      }
    }
  })

  depends_on = [
    helm_release.opentelemetry_operator
  ]
}
