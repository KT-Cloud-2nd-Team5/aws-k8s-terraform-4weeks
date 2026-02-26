# -----------------------------------------------------------------------------
# Bastion Security Groups
# -----------------------------------------------------------------------------

resource "aws_security_group" "bastion" {
  name        = "sg_bastion"
  description = "Security Group for Bastion Host"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "SG-Bastion"
  }
}

resource "aws_security_group_rule" "bastion_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.pc_public_ips
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from PC"
}

resource "aws_security_group_rule" "bastion_ingress_proxy" {
  type              = "ingress"
  from_port         = 3128
  to_port           = 3128
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.bastion.id
  description       = "proxy"
}

resource "aws_security_group_rule" "bastion_prometheus_from_pc" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = var.pc_public_ips             # 출발
  security_group_id = aws_security_group.bastion.id # 도착
  description       = "Prometheus from PC"          # cidr_blocks에서 sg로 ingress 9900 뚫음
}

resource "aws_security_group_rule" "bastion_prometheus_from_k3s" {
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k3s_nodes.id
  security_group_id        = aws_security_group.bastion.id
  description              = "Prometheus from K3s nodes"
}

resource "aws_security_group_rule" "bastion_ingress_grafana" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = var.pc_public_ips
  security_group_id = aws_security_group.bastion.id
  description       = "Grafana"
}

resource "aws_security_group_rule" "bastion_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
  description       = "Allow all outbound traffic"
}

# -----------------------------------------------------------------------------
# Master Security Groups
# -----------------------------------------------------------------------------
resource "aws_security_group" "k3s_master" {
  name   = "sg_k3s_master"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "SG-K3s-Master"
  }
}

resource "aws_security_group_rule" "master_ingress_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.k3s_master.id
  description              = "SSH from Bastion"
}

resource "aws_security_group_rule" "master_ingress_api_from_nodes" {
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

resource "aws_security_group_rule" "master_ingress_flannel_from_master" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.k3s_master.id
  security_group_id        = aws_security_group.k3s_master.id
  description              = "Flannel VXLAN from Master"
}

resource "aws_security_group_rule" "master_ingress_flannel_from_nodes" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.k3s_nodes.id
  security_group_id        = aws_security_group.k3s_master.id
  description              = "Flannel VXLAN from Nodes"
}

resource "aws_security_group_rule" "master_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k3s_master.id
}

# -----------------------------------------------------------------------------
# nodes Security Groups
# -----------------------------------------------------------------------------
resource "aws_security_group" "k3s_nodes" {
  name   = "sg_k3s_nodes"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "SG-K3s-Nodes"
  }
}

resource "aws_security_group_rule" "nodes_ingress_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.k3s_nodes.id
  description              = "SSH from Bastion"
}

resource "aws_security_group_rule" "nodes_ingress_flannel_from_nodes" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.k3s_nodes.id
  security_group_id        = aws_security_group.k3s_nodes.id
  description              = "Flannel VXLAN from Nodes"
}

resource "aws_security_group_rule" "nodes_ingress_flannel_from_master" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.k3s_master.id
  security_group_id        = aws_security_group.k3s_nodes.id
  description              = "Flannel VXLAN from Master Nodes"
}

resource "aws_security_group_rule" "nodes_ingress_http_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.k3s_nodes.id
  description              = "Allow HTTP traffic from ALB to k3s ingress controller"
}

resource "aws_security_group_rule" "nodes_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k3s_nodes.id
}

# -----------------------------------------------------------------------------
# Other Security Groups
# -----------------------------------------------------------------------------


resource "aws_security_group" "monitoring" {
  name   = "sg_monitoring"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"]
    security_groups = [aws_security_group.bastion.id]
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
  name        = "sg_alb"
  description = "Security Group for ALB"
  vpc_id      = aws_vpc.main.id

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
  tags = { Name = "SG-ALB" }
}
