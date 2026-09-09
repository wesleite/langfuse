data "aws_secretsmanager_secret" "fluentbit_elastic_user" {
  provider = aws.solides-infrastructure
  name     = "k8s-fluentbit-elastic-user-secret"
}

data "aws_secretsmanager_secret_version" "fluentbit_elastic_user" {
  provider  = aws.solides-infrastructure
  secret_id = data.aws_secretsmanager_secret.fluentbit_elastic_user.id
}
