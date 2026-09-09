resource "aws_iam_role" "this" {
  name = "eks-${var.k8s_namespace}-${var.k8s_application_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = var.cluster_eks_outputs.oidc_provider_arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${var.cluster_eks_outputs.oidc_provider}:sub" = "system:serviceaccount:${var.k8s_namespace}:${var.k8s_application_name}"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "this" {
  count  = var.aws_iam_policy_json != "" ? 1 : 0
  name   = "eks-${var.k8s_namespace}-${var.k8s_application_name}"
  policy = var.aws_iam_policy_json
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  count      = var.aws_iam_policy_json != "" ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[0].arn
}

resource "vault_policy" "this" {
  name = "${var.k8s_namespace}_${var.k8s_application_name}"

  policy = <<EOT
path "k8s/data/${var.k8s_namespace}/${var.k8s_application_name}" {
  capabilities = ["read"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "this" {
  backend                          = "kubernetes"
  role_name                        = "${var.k8s_namespace}_${var.k8s_application_name}"
  bound_service_account_names      = [var.k8s_application_name]
  bound_service_account_namespaces = [var.k8s_namespace]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.this.name]
  audience                         = "https://kubernetes.default.svc"
}

resource "vault_kv_secret_v2" "this" {
  mount               = "k8s"
  name                = "${var.k8s_namespace}/${var.k8s_application_name}"
  delete_all_versions = true
  data_json           = "{}"
}

resource "vault_kv_secret_v2" "cicd" {
  mount               = "cicd"
  name                = "${var.k8s_namespace}/${var.k8s_application_name}"
  delete_all_versions = true
  data_json           = "{}"
}
