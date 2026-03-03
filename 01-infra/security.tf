# -----------------------------------------------------------------------------
# Bastion Security Groups
# -----------------------------------------------------------------------------

resource "aws_security_group" "bastion" {
  name        = "sg_bastion"
  description = "Security Group for Bastion Host"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "SG-Bastion" }
}

# Rule 1: SSH from My PC
resource "aws_security_group_rule" "bastion_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.pc_public_ips
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from Admin PC"
}

# Rule 2: Proxy (Squid) from VPC internal (Layer 2 nodes will use this)
resource "aws_security_group_rule" "bastion_ingress_proxy" {
  type              = "ingress"
  from_port         = 3128
  to_port           = 3128
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.bastion.id
  description       = "Allow Proxy access from internal VPC"
}

# Rule 3: Prometheus (9090) from PC
resource "aws_security_group_rule" "bastion_ingress_prometheus" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = var.pc_public_ips
  security_group_id = aws_security_group.bastion.id
}


# Grafana 접속 허용 (필요시 추가)
resource "aws_security_group_rule" "bastion_ingress_grafana" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = var.pc_public_ips
  security_group_id = aws_security_group.bastion.id
  description       = "Grafana from Admin PC"
}

# Rule 4: Egress All
resource "aws_security_group_rule" "bastion_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}
