data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket  = "terraform-tfstates-654654517121"
    key     = "terraform-k8s/aws-corp-staging/eks/terraform.tfstate"
    region  = "us-east-1"
    profile = "solides-infrastructure"
  }
}
