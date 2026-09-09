locals {
  gitlab_runner_values_yaml = <<-YAML
    aws: {}

    azure:
      podLabels:
        azure.workload.identity/use: "true"
  YAML

  gitlab_runner_service_account_annotations_yaml = <<-YAML
    aws:
      eks.amazonaws.com/role-arn: ${var.gitlab_runner_identifier}

    azure:
      azure.workload.identity/client-id: ${var.gitlab_runner_identifier}
  YAML

  gitlab_runner_values = try(
    yamldecode(local.gitlab_runner_values_yaml)[var.cloud_provider], {}
  )

  gitlab_runner_service_account_annotations = try(
    yamldecode(local.gitlab_runner_service_account_annotations_yaml)[var.cloud_provider], {}
  )
}

resource "helm_release" "gitlab_runner" {
  for_each         = var.gitlab_runner_enabled ? toset(keys(nonsensitive(var.gitlab_runner_tokens))) : toset([])
  name             = "gitlab-runner-${each.key}"
  namespace        = "cicd"
  create_namespace = true

  repository = "https://charts.gitlab.io"
  chart      = "gitlab-runner"
  version    = "0.80.0"

  set = [
    {
      name  = "runnerToken"
      value = var.gitlab_runner_tokens[each.key]
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account_v1.gitlab_runner[0].metadata[0].name
    }
  ]

  values = [
    file("${path.module}/values/gitlab_runner/values.yaml"),
    yamlencode(local.gitlab_runner_values)
  ]

  depends_on = [
    kubernetes_service_account_v1.gitlab_runner
  ]
}

resource "kubernetes_service_account_v1" "gitlab_runner" {
  count = var.gitlab_runner_enabled ? 1 : 0

  metadata {
    name        = "gitlab-runner"
    namespace   = kubernetes_namespace_v1.cicd.metadata[0].name
    annotations = local.gitlab_runner_service_account_annotations
  }
}
