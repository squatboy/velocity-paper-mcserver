# Velocity Server 보안 그룹 (Public Subnet용)
resource "aws_security_group" "mcserver_velocity_sg" {
  name        = "${var.project_name}-velocity-sg"
  description = "Security group for Velocity server"
  vpc_id      = var.vpc_id
  tags = {
    Name = "${var.project_name}-velocity-sg"
  }
}

# Paper Server 보안 그룹 (Private Subnet용)
resource "aws_security_group" "mcserver_paper_sg" {
  name        = "${var.project_name}-paper-sg"
  description = "Security group for Paper Minecraft servers"
  vpc_id      = var.vpc_id
  tags = {
    Name = "${var.project_name}-paper-sg"
  }
}

# Velocity Proxy 인바운드 규칙 (클라이언트 접속)
resource "aws_vpc_security_group_ingress_rule" "velocity_ingress" {
  security_group_id = aws_security_group.mcserver_velocity_sg.id
  from_port         = 25565
  to_port           = 25565
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Minecraft client connections"
}

# Velocity Proxy SSH 인바운드 규칙 (전체 인터넷 허용)
resource "aws_vpc_security_group_ingress_rule" "velocity_ssh_ingress" {
  security_group_id = aws_security_group.mcserver_velocity_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "SSH access from anywhere"
}

# Grafana UI 인바운드 규칙 (운영자 고정 IP만 허용)
resource "aws_vpc_security_group_ingress_rule" "grafana_ingress" {
  security_group_id = aws_security_group.mcserver_velocity_sg.id
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  cidr_ipv4         = var.admin_ip
  description       = "Grafana UI access (restricted)"
}

# Paper Server 인바운드 규칙 (Proxy에서만 허용)
resource "aws_vpc_security_group_ingress_rule" "paper_ingress" {
  security_group_id = aws_security_group.mcserver_paper_sg.id
  from_port         = 25501
  to_port           = 25503
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.mcserver_velocity_sg.id
  description       = "Connections from Velocity"
}

# Paper Server SSH 인바운드 규칙 (Velocity에서만 허용)
resource "aws_vpc_security_group_ingress_rule" "paper_ssh_ingress" {
  security_group_id = aws_security_group.mcserver_paper_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.mcserver_velocity_sg.id
  description       = "SSH access from Velocity server"
}

# Velocity Proxy 아웃바운드 규칙 (모든 outbound 허용)
resource "aws_vpc_security_group_egress_rule" "velocity_egress" {
  security_group_id = aws_security_group.mcserver_velocity_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "All outbound traffic"
}

# Paper Server 아웃바운드 규칙 (모든 outbound 허용)
resource "aws_vpc_security_group_egress_rule" "paper_egress" {
  security_group_id = aws_security_group.mcserver_paper_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "All outbound traffic"
}


