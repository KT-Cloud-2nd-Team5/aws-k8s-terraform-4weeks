# -----------------------------------------------------------------------------
# Provider & Versions
# -----------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2" # 서울 리전
}


# -----------------------------------------------------------------------------
# Data Sources (AMI, AZ 정보 조회)
# -----------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}


# -----------------------------------------------------------------------------
# EC2 Instances
# -----------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public_a.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  # squid proxy 설정
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install squid -y              
              sed -i 's/http_access deny all/http_access allow all/g' /etc/squid/squid.conf
              systemctl restart squid
              EOF

  tags = { Name = "EC2-Bastion" }
}

resource "aws_instance" "k3s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private_a.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k3s_master.id]
  tags                   = { Name = "K3s-Master" }
}

resource "aws_instance" "web_worker_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k3s_nodes.id]
  tags                   = { Name = "K3s-Web-01" }
}

resource "aws_instance" "web_worker_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_a.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k3s_nodes.id]
  tags                   = { Name = "K3s-Web-02" }
}

resource "aws_instance" "db_worker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_a.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k3s_nodes.id]
  tags                   = { Name = "K3s-DB-01" }
}
