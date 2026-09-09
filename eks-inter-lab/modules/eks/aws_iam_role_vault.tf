data "aws_iam_policy_document" "vault_assume_role_policy" {
  count = var.vault_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:vault:vault"]
    }
  }
}

data "aws_iam_policy_document" "vault_policy_custom" {
  count = var.vault_enabled ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [local.vault_kms_key_arn]
  }
}

resource "aws_iam_role" "vault" {
  count              = var.vault_enabled ? 1 : 0
  name               = "${var.cluster_name}-vault"
  assume_role_policy = data.aws_iam_policy_document.vault_assume_role_policy[0].json
  tags               = local.tags
}

resource "aws_iam_role_policy" "vault_policy_custom" {
  count  = var.vault_enabled ? 1 : 0
  name   = "${var.cluster_name}-vault"
  role   = aws_iam_role.vault[0].id
  policy = data.aws_iam_policy_document.vault_policy_custom[0].json
}
