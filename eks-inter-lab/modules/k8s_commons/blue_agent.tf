resource "kubernetes_secret_v1" "blue_agent" {
  count = var.cloud_provider == "aws" && var.blue_agent_enabled ? 1 : 0

  metadata {
    name      = "blue-agent-secret"
    namespace = "cicd"
  }

  data = {
    organizationURL     = var.blue_agent_organization_url
    personalAccessToken = var.blue_agent_personal_access_token
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace_v1.cicd
  ]
}

resource "helm_release" "blue_agent" {
  count            = var.cloud_provider == "aws" && var.blue_agent_enabled ? 1 : 0
  name             = "blue-agent"
  namespace        = "cicd"
  create_namespace = true

  repository = "https://clemlesne.github.io/blue-agent"
  chart      = "blue-agent"
  version    = "11.0.0"

  set = [
    {
      name  = "pipelines.poolName"
      value = "blue-agent-${var.cluster_name}"
    }
  ]

  values = [
    file("${path.module}/values/blue_agent/values.yaml")
  ]

  depends_on = [
    kubernetes_secret_v1.blue_agent,
    helm_release.keda,
  ]
}

resource "kubernetes_cluster_role_v1" "blue_agent_role" {
  count = var.cloud_provider == "aws" && var.blue_agent_enabled ? 1 : 0

  metadata {
    name = "blue-agent-role"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  depends_on = [
    helm_release.blue_agent
  ]
}

resource "kubernetes_cluster_role_binding_v1" "blue_agent_binding" {
  count = var.cloud_provider == "aws" && var.blue_agent_enabled ? 1 : 0

  metadata {
    name = "blue-agent-role-binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "blue-agent"
    namespace = "cicd"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.blue_agent_role[0].metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [
    helm_release.blue_agent,
    kubernetes_cluster_role_v1.blue_agent_role,
  ]
}
