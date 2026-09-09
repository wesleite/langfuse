data "aws_iam_policy_document" "thanos_sidecar_policy_custom" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::thanos-monitoring-infrastructure",
      "arn:aws:s3:::thanos-monitoring-infrastructure/*",
    ]
  }
}

data "aws_iam_policy_document" "thanos_sidecar_assume_role_policy" {
  count = var.prometheus_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:monitoring:kube-prometheus-stack-prometheus"]
    }
  }
}

resource "aws_iam_role" "thanos_sidecar" {
  count              = var.prometheus_enabled ? 1 : 0
  name               = "${var.cluster_name}-thanos-sidecar"
  provider           = aws.solides-infrastructure
  assume_role_policy = data.aws_iam_policy_document.thanos_sidecar_assume_role_policy[0].json
  tags               = local.tags
}

resource "aws_iam_role_policy" "thanos_sidecar_policy_custom" {
  count    = var.prometheus_enabled ? 1 : 0
  provider = aws.solides-infrastructure
  name     = "${var.cluster_name}-thanos-sidecar"
  role     = aws_iam_role.thanos_sidecar[0].id
  policy   = data.aws_iam_policy_document.thanos_sidecar_policy_custom.json
}
