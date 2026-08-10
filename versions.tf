terraform {
  required_version = ">= 1.7.0"

  backend "s3" {
    bucket = "gaurav-three-tier-tfstate"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    random = {
      source = "hashicorp/random"
    }
  }
}
