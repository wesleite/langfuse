resource "helm_release" "aws_iam_role_injector" {
  count            = var.cloud_provider == "azure" ? 1 : 0
  name             = "aws-iam-role-injector"
  namespace        = "kube-system"
  create_namespace = true

  repository = "oci://public.ecr.aws/g6y2f6g9"
  chart      = "aws-iam-role-injector"
  version    = "1.0.0"

  repository_username = data.aws_ecrpublic_authorization_token.public.user_name
  repository_password = data.aws_ecrpublic_authorization_token.public.password

  values = [
    file("${path.module}/values/aws_iam_role_injector/values.yaml")
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}
