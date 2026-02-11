# -----------------------------------------------------------------------------
# Beckend (s3 & dynamodb_table)
# for save terraform state
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "team5-tfstate"
    key            = "dev/terraform.tfstate" # 저장될 경로 및 파일명
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
    profile        = "first_project"
  }
}

data "aws_s3_bucket" "tfstate_bucket" {
  bucket = "team5-tfstate"
}
