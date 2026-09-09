module "k8s_commons" {
  source                                  = "../k8s_commons"
  cloud_provider                          = "aws"
  cluster_name                            = var.cluster_name
  dns_domain                              = var.route53_domain
  slogger_context                         = var.slogger_context
  slogger_environment                     = var.environment
  environment                             = var.environment == "prod" ? "production" : var.environment
  aws_profile                             = var.aws_profile
  aws_region                              = data.aws_region.current.name
  aws_vpc_id                              = data.aws_vpc.selected.id
  aws_acm_certificate_arn                 = module.acm.acm_certificate_arn
  argocd_enabled                          = var.argocd_enabled
  blue_agent_enabled                      = var.blue_agent_enabled
  gitlab_runner_enabled                   = var.gitlab_runner_enabled
  prometheus_enabled                      = var.prometheus_enabled
  vault_enabled                           = var.vault_enabled
  k8s_cleaner_enabled                     = var.k8s_cleaner_enabled
  gitlab_runner_node_isolation_enabled    = var.gitlab_runner_node_isolation_enabled
  vault_node_isolation_enabled            = var.environment == "prod"
  aws_load_balancer_controller_identifier = aws_iam_role.aws_load_balancer_controller.arn
  cluster_autoscaler_identifier           = aws_iam_role.cluster_autoscaler.arn
  external_dns_identifier                 = aws_iam_role.external_dns.arn
  gitlab_runner_identifier                = aws_iam_role.gitlab_runner.arn
  vault_identifier                        = var.vault_enabled ? aws_iam_role.vault[0].arn : ""
  argocd_azure_password                   = jsondecode(data.aws_secretsmanager_secret_version.argocd_azure_password.secret_string)["password"]
  argocd_dex_google_sso_client_id         = jsondecode(data.aws_secretsmanager_secret_version.argocd_dex_google_sso.secret_string)["clientID"]
  argocd_dex_google_sso_client_secret     = jsondecode(data.aws_secretsmanager_secret_version.argocd_dex_google_sso.secret_string)["clientSecret"]
  argocd_gitlab_password                  = jsondecode(data.aws_secretsmanager_secret_version.argocd_gitlab_password.secret_string)["password"]
  blue_agent_organization_url             = jsondecode(data.aws_secretsmanager_secret_version.blue_agent.secret_string)["organizationURL"]
  blue_agent_personal_access_token        = jsondecode(data.aws_secretsmanager_secret_version.blue_agent.secret_string)["personalAccessToken"]
  fluentbit_elastic_password              = jsondecode(data.aws_secretsmanager_secret_version.fluentbit_elastic_user.secret_string)["password"]
  fluentbit_elastic_user                  = jsondecode(data.aws_secretsmanager_secret_version.fluentbit_elastic_user.secret_string)["username"]
  gitlab_runner_tokens                    = var.gitlab_runner_enabled ? tomap(jsondecode(one(data.aws_secretsmanager_secret_version.gitlab_runner).secret_string)["tokens"]) : {}
  prometheus_aws_iam_role_arn             = var.prometheus_enabled ? aws_iam_role.thanos_sidecar[0].arn : ""
  prometheus_disk_size_gb                 = var.prometheus_disk_size_gb
  vault_aws_kms_key_arn                   = local.vault_kms_key_arn

  depends_on = [
    module.eks
  ]

  providers = {
    aws.solides-infrastructure = aws.solides-infrastructure
  }
}
