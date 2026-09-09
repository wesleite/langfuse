terraform {
  required_version = ">= 1.14.5"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.7"
    }
  }
}
