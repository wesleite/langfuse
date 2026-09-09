terraform {
  backend "s3" {
    bucket       = "terraform-tfstates-654654517121"
    key          = "terraform-k8s/aws-corp-staging/eks_applications/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    profile      = "solides-infrastructure"
  }
}
