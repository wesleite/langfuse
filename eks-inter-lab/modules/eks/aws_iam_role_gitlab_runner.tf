data "aws_iam_role" "infrastructure_gitlab_runner" {
  provider = aws.solides-infrastructure
  name     = "eks-infrastructure-prod-gitlab-runner"
}

data "aws_iam_policy_document" "gitlab_runner_assume_role_policy" {
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
      values   = ["system:serviceaccount:cicd:gitlab-runner"]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.infrastructure_gitlab_runner.arn]
    }
  }
}

resource "aws_iam_role" "gitlab_runner" {
  name               = "${var.cluster_name}-gitlab-runner"
  assume_role_policy = data.aws_iam_policy_document.gitlab_runner_assume_role_policy.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "gitlab_runner_admin" {
  role       = aws_iam_role.gitlab_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
