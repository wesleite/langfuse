data "aws_eks_cluster" "cluster" {
  name = "eks-corp-staging"
}

data "aws_secretsmanager_secret" "vault_secret" {
  name = "k8s-vault-secret"
}

data "aws_secretsmanager_secret_version" "vault_secret" {
  secret_id = data.aws_secretsmanager_secret.vault_secret.id
}

data "aws_secretsmanager_secret" "vault_oidc_secret" {
  name     = "k8s-vault-oidc-secret"
  provider = aws.solides-infrastructure
}

data "aws_secretsmanager_secret_version" "vault_oidc_secret" {
  secret_id = data.aws_secretsmanager_secret.vault_oidc_secret.id
  provider  = aws.solides-infrastructure
}

locals {
  vault_secret_data      = jsondecode(data.aws_secretsmanager_secret_version.vault_secret.secret_string)
  vault_oidc_secret_data = jsondecode(data.aws_secretsmanager_secret_version.vault_oidc_secret.secret_string)
}

module "eks_corp_staging_k8s_vault_config" {
  source                     = "../../modules/k8s_vault_config"
  kubernetes_ca_cert         = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  vault_address              = "https://vault.corp-staging.solides.com.br"
  vault_root_token           = local.vault_secret_data["root_token"]
  vault_oidc_bound_audiences = [local.vault_oidc_secret_data["bound_audiences"]]
  vault_oidc_client_id       = local.vault_oidc_secret_data["oidc_client_id"]
  vault_oidc_client_secret   = local.vault_oidc_secret_data["oidc_client_secret"]
}
