terraform {
  required_version = ">= 1.14.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 6.0.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.1.1"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "= 2.2.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0.1"
    }
  }
}
