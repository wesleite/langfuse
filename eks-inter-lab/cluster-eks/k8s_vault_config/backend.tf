terraform {
  backend "s3" {
    bucket       = "terraform-tfstates-654654517121"
    key          = "terraform-k8s/aws-corp-staging/k8s_vault_config/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    profile      = "solides-infrastructure"
  }
}
