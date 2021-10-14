terraform {
  backend "s3" {
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.9.0"
    }
  }
  required_version = ">= 0.15.0, < 2.0.0"
}
