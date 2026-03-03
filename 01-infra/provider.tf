# -----------------------------------------------------------------------------
# Provider & Versions & Backend
# -----------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "team5-tfstate"
    key            = "dev/base-infra/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}
