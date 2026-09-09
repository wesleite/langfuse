locals {
  cluster_autoscaler_values_yaml = <<-YAML
    aws:
      autoDiscovery:
        clusterName: ${var.cluster_name}
      awsRegion: ${var.aws_region}

    azure: {}
  YAML

  cluster_autoscaler_values = try(
    yamldecode(local.cluster_autoscaler_values_yaml)[var.cloud_provider], {}
  )

  cluster_autoscaler_service_account_annotations_yaml = <<-YAML
    aws:
      eks.amazonaws.com/role-arn: ${var.cluster_autoscaler_identifier}

    azure: {}
  YAML

  cluster_autoscaler_service_account_annotations = try(
    yamldecode(local.cluster_autoscaler_service_account_annotations_yaml)[var.cloud_provider], {}
  )
}

resource "helm_release" "cluster_autoscaler" {
  count            = var.cloud_provider == "aws" ? 1 : 0
  name             = "cluster-autoscaler"
  namespace        = "kube-system"
  create_namespace = true

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.46.6"

  values = [
    file("${path.module}/values/cluster_autoscaler/values.yaml"),
    yamlencode(local.cluster_autoscaler_values),
    yamlencode({
      rbac = {
        serviceAccount = {
          annotations = local.cluster_autoscaler_service_account_annotations
        }
      }
    })
  ]
}
