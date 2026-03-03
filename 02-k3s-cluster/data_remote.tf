# 01-infra layer에서 생성된 output을 s3 버킷에서 가져와서 사용
data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = "team5-tfstate"
    key    = "dev/base-infra/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# 로컬 변수로 맵핑
locals {
  vpc_id   = data.terraform_remote_state.base.outputs.vpc_id
  vpc_cidr = data.terraform_remote_state.base.outputs.vpc_cidr
  public_subnet_ids = [
    data.terraform_remote_state.base.outputs.public_subnet_a,
    data.terraform_remote_state.base.outputs.public_subnet_c
  ]
  private_subnet_ids = [
    data.terraform_remote_state.base.outputs.private_subnet_a
  ]
  bastion_sg_id   = data.terraform_remote_state.base.outputs.bastion_sg_id
  bastion_priv_ip = data.terraform_remote_state.base.outputs.bastion_private_ip
  bastion_pub_ip  = data.terraform_remote_state.base.outputs.bastion_public_ip
}

