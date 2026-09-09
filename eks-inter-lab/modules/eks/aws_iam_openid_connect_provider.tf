resource "aws_iam_openid_connect_provider" "eks" {
  count    = var.prometheus_enabled ? 1 : 0
  provider = aws.solides-infrastructure
  url      = module.eks.cluster_oidc_issuer_url

  client_id_list = [
    "sts.amazonaws.com"
  ]
}
