provider "aws" {
  region  = "us-east-1"
  profile = "solides-ti-corp-staging"
}

provider "aws" {
  alias   = "solides-infrastructure"
  region  = "us-east-1"
  profile = "solides-infrastructure"
}

data "aws_secretsmanager_secret" "vault_secret" {
  name = "k8s-vault-secret"
}

data "aws_secretsmanager_secret_version" "vault_secret" {
  secret_id = data.aws_secretsmanager_secret.vault_secret.id
}

locals {
  vault_secret_data = jsondecode(data.aws_secretsmanager_secret_version.vault_secret.secret_string)
}

provider "vault" {
  token   = local.vault_secret_data["root_token"]
  address = "https://vault.corp-staging.solides.com.br"
}