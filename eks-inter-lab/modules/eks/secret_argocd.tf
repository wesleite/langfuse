data "aws_secretsmanager_secret" "argocd_dex_google_sso" {
  provider = aws.solides-infrastructure
  name     = "k8s-argocd-dex-google-sso-secret"
}

data "aws_secretsmanager_secret_version" "argocd_dex_google_sso" {
  provider  = aws.solides-infrastructure
  secret_id = data.aws_secretsmanager_secret.argocd_dex_google_sso.id
}

data "aws_secretsmanager_secret" "argocd_azure_password" {
  provider = aws.solides-infrastructure
  name     = "k8s-argocd-azure-password"
}

data "aws_secretsmanager_secret_version" "argocd_azure_password" {
  provider  = aws.solides-infrastructure
  secret_id = data.aws_secretsmanager_secret.argocd_azure_password.id
}

data "aws_secretsmanager_secret" "argocd_gitlab_password" {
  provider = aws.solides-infrastructure
  name     = "k8s-argocd-gitlab-password"
}

data "aws_secretsmanager_secret_version" "argocd_gitlab_password" {
  provider  = aws.solides-infrastructure
  secret_id = data.aws_secretsmanager_secret.argocd_gitlab_password.id
}
