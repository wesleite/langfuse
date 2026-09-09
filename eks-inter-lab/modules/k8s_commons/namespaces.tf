resource "kubernetes_namespace_v1" "cert_manager" {
  count = var.cloud_provider == "azure" ? 1 : 0

  metadata {
    name = "cert-manager"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels["field.cattle.io/projectId"]
    ]
  }
}

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels["field.cattle.io/projectId"]
    ]
  }
}

resource "kubernetes_namespace_v1" "logs" {
  metadata {
    name = "logs"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels["field.cattle.io/projectId"]
    ]
  }
}

resource "kubernetes_namespace_v1" "cicd" {
  metadata {
    name = "cicd"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels["field.cattle.io/projectId"]
    ]
  }
}

resource "kubernetes_namespace_v1" "external_dns" {
  metadata {
    name = "external-dns"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels["field.cattle.io/projectId"]
    ]
  }
}
