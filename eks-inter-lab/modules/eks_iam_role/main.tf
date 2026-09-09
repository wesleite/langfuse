resource "aws_iam_role" "this" {
  name = "eks-${var.namespace}-${var.service_account_name}"

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
          "${var.cluster_eks_outputs.oidc_provider}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "this" {
  name   = "eks-${var.namespace}-${var.service_account_name}"
  policy = var.policy_json
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
