
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------------
# EC2 Instances
# -----------------------------------------------------------------------------
resource "aws_instance" "k3s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = local.private_subnet_ids[0]
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k3s_master.id]

  tags = {
    Name        = "K3s-Master"
    Role        = "master"
    Environment = "dev"
  }

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
}

resource "aws_instance" "web_worker_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = local.public_subnet_ids[0] # Public A
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k3s_nodes.id]

  tags = {
    Name        = "K3s-Web-01"
    Role        = "web"
    Type        = "workers"
    Environment = "dev"
  }

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
}

resource "aws_instance" "web_worker_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = local.public_subnet_ids[1] # Public C
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k3s_nodes.id]

  tags = {
    Name        = "K3s-Web-02"
    Role        = "web"
    Type        = "workers"
    Environment = "dev"
  }

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
}

resource "aws_instance" "db_worker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = local.private_subnet_ids[0]
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k3s_nodes.id]

  tags = {
    Name        = "K3s-DB-01"
    Role        = "db"
    Type        = "workers"
    Environment = "dev"
  }

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
}
