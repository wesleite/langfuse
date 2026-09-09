data "aws_secretsmanager_secret" "blue_agent" {
  provider = aws.solides-infrastructure
  name     = "k8s-blue-agent-secret"
}

data "aws_secretsmanager_secret_version" "blue_agent" {
  provider  = aws.solides-infrastructure
  secret_id = data.aws_secretsmanager_secret.blue_agent.id
}
