terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Values are supplied at `terraform init` time via -backend-config flags
  # in the GitHub Actions workflow, so no hardcoded bucket/table name lives
  # in source control (the bucket name is generated per-account at runtime).
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
