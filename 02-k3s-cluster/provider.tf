terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "team5-tfstate"
    key            = "dev/k3s-cluster/terraform.tfstate" # 경로 다름
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}
