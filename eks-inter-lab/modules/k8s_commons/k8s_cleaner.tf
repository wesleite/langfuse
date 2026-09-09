resource "helm_release" "k8s_cleaner" {
  count            = var.k8s_cleaner_enabled ? 1 : 0
  name             = "k8s-cleaner"
  namespace        = "kube-system"
  create_namespace = true

  repository = "oci://public.ecr.aws/g6y2f6g9"
  chart      = "k8s-cleaner"
  version    = "1.0.0"

  repository_username = data.aws_ecrpublic_authorization_token.public.user_name
  repository_password = data.aws_ecrpublic_authorization_token.public.password

  set = [
    {
      name  = "podAnnotations.slogger"
      value = "true"
      type  = "string"
    },
    {
      name  = "podAnnotations.slogger_index_prefix"
      value = "logs-${var.slogger_environment}-eks-${var.slogger_context}-k8s-cleaner"
    }
  ]

  values = [
    file("${path.module}/values/k8s_cleaner/values.yaml")
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}
