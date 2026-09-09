module "eks_application_renegociacao_boletos" {
  source               = "../../modules/eks_application"
  cluster_eks_outputs  = data.terraform_remote_state.eks.outputs.cluster_eks_outputs
  k8s_application_name = "renegociacao-boletos"
  k8s_namespace        = "hyperautomation"

  aws_iam_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::hyperautomation-artefatos-staging"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::hyperautomation-artefatos-staging/*"
      }
    ]
  })
}