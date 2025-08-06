resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# IGW 생성
resource "aws_internet_gateway" "mcserver_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet 생성 (Proxy EC2용)
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone

  # Public IP 자동 할당
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Private Subnet 생성 (Paper EC2용)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone
  
  tags = {
    Name = "${var.project_name}-private-subnet"
  }
}

# NAT Gateway용 Elastic IP 생성
resource "aws_eip" "nat" {
  domain = "vpc"

  # IGW가 생성된 후에 EIP 생성
  depends_on = [aws_internet_gateway.mcserver_igw]
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# NAT Gateway 생성 (Private Subnet 아웃바운드용)
resource "aws_nat_gateway" "mcserver_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  # IGW가 생성된 후에 NAT Gateway 생성
  depends_on = [aws_internet_gateway.mcserver_igw]
  tags = {
    Name = "${var.project_name}-natgw"
  }
}

# Public 라우팅 테이블 생성
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # IGW로 라우팅
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mcserver_igw.id
  }
}

# Private 라우팅 테이블 생성
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # NAT Gateway로 라우팅
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mcserver_nat.id
  }
}

# Public Subnet과 Public 라우팅 테이블 연결
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private Subnet과 Private 라우팅 테이블 연결
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}


# =============================================================================
# SSM
# =============================================================================
resource "aws_security_group" "ssm_endpoint_sg" {
  name        = "${var.project_name}-ssm-endpoint-sg"
  description = "Allow TLS from private subnet to SSM VPC endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  tags = {
    Name = "${var.project_name}-ssm-endpoint-sg"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private.id
  ]

  security_group_ids = [
    aws_security_group.ssm_endpoint_sg.id
  ]

  tags = {
    Name = "${var.project_name}-ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private.id
  ]

  security_group_ids = [
    aws_security_group.ssm_endpoint_sg.id
  ]

  tags = {
    Name = "${var.project_name}-ssmmessages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private.id
  ]

  security_group_ids = [
    aws_security_group.ssm_endpoint_sg.id
  ]

  tags = {
    Name = "${var.project_name}-ec2messages-endpoint"
  }
}
