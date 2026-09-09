data "aws_secretsmanager_secret" "gitlab_runner" {
  count = var.gitlab_runner_enabled ? 1 : 0
  name  = "k8s-gitlab-runner-secret"
}

data "aws_secretsmanager_secret_version" "gitlab_runner" {
  count     = var.gitlab_runner_enabled ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.gitlab_runner[0].id
}
