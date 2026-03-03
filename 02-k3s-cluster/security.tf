# --- Groups ---
resource "aws_security_group" "k3s_master" {
  name   = "sg_k3s_master"
  vpc_id = local.vpc_id
  tags   = { Name = "SG-K3s-Master" }
}

resource "aws_security_group" "k3s_nodes" {
  name   = "sg_k3s_nodes"
  vpc_id = local.vpc_id
  tags   = { Name = "SG-K3s-Nodes" }
}

resource "aws_security_group" "alb" {
  name   = "sg_alb"
  vpc_id = local.vpc_id
  tags   = { Name = "SG-ALB" }
}

# --- Rules: Master ---
resource "aws_security_group_rule" "master_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = local.bastion_sg_id
  security_group_id        = aws_security_group.k3s_master.id
}

resource "aws_security_group_rule" "master_api_from_nodes" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s_nodes.id
  security_group_id        = aws_security_group.k3s_master.id
}

resource "aws_security_group_rule" "master_flannel_udp" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.k3s_nodes.id
  security_group_id        = aws_security_group.k3s_master.id
}

resource "aws_security_group_rule" "master_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k3s_master.id
}

# --- Rules: Nodes ---
resource "aws_security_group_rule" "nodes_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = local.bastion_sg_id
  security_group_id        = aws_security_group.k3s_nodes.id
}

resource "aws_security_group_rule" "nodes_http_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.k3s_nodes.id
}

resource "aws_security_group_rule" "nodes_flannel_udp" {
  type              = "ingress"
  from_port         = 8472
  to_port           = 8472
  protocol          = "udp"
  self              = true # Allow from other nodes in same SG
  security_group_id = aws_security_group.k3s_nodes.id
}

resource "aws_security_group_rule" "nodes_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k3s_nodes.id
}

# --- Rules: ALB ---
resource "aws_security_group_rule" "alb_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}


# --- Rules: Bastion ---
resource "aws_security_group_rule" "bastion_prometheus_from_k3s" {
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s_nodes.id
  security_group_id        = var.bastion_sg_id
  description              = "Prometheus from K3s nodes"
}
