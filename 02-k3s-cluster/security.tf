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


# --- Rules: Master ---
resource "aws_security_group_rule" "master_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = local.bastion_sg_id
  security_group_id        = aws_security_group.k3s_master.id
  description              = "SSH from Bastion"
}

resource "aws_security_group_rule" "master_api_from_nodes" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s_nodes.id
  security_group_id        = aws_security_group.k3s_master.id
  description              = "Kube API from Nodes"
}

resource "aws_security_group_rule" "master_ingress_api_from_master" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s_master.id
  security_group_id        = aws_security_group.k3s_master.id
  description              = "Kube API from Master"
}

resource "aws_security_group_rule" "master_flannel_udp_from_nodes" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.k3s_nodes.id
  security_group_id        = aws_security_group.k3s_master.id
}

resource "aws_security_group_rule" "master_ingress_flannel_from_master" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.k3s_master.id
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
  self              = true
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


# --- Rules: others ---
resource "aws_security_group" "monitoring" {
  name   = "sg_monitoring"
  vpc_id = local.vpc_id

  ingress {
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"]
    security_groups = [local.bastion_sg_id]
    description     = "Allow Prometheus on Bastion to scrape Node Exporter"
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow Kubelet API for HPA"
  }

  tags = {
    Name = "SG-Monitoring"
  }
}

resource "aws_security_group" "alb" {
  name   = "sg_alb"
  vpc_id = local.vpc_id
  tags   = { Name = "SG-ALB" }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Rules: Bastion ---
resource "aws_security_group_rule" "bastion_prometheus_from_k3s" {
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s_nodes.id
  security_group_id        = local.bastion_sg_id
  description              = "Prometheus from K3s nodes"
}
