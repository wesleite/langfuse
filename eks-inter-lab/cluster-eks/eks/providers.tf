provider "aws" {
  region  = "us-east-1"
  profile = "solides-ti-corp-staging"
}

provider "aws" {
  alias   = "solides-infrastructure"
  region  = "us-east-1"
  profile = "solides-infrastructure"
}
