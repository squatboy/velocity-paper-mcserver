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

# 테스트용 ㅋㅋ
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone
  # Public IP 자동 할당
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-private-subnet"
  }
}

# # Private Subnet 생성 (Paper EC2용)
# resource "aws_subnet" "private" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = var.private_subnet_cidr
#   availability_zone = var.availability_zone
  
#   tags = {
#     Name = "${var.project_name}-private-subnet"
#   }
# }

# # NAT Gateway용 Elastic IP 생성
# resource "aws_eip" "nat" {
#   domain = "vpc"

#   # IGW가 생성된 후에 EIP 생성
#   depends_on = [aws_internet_gateway.mcserver_igw]
#   tags = {
#     Name = "${var.project_name}-nat-eip"
#   }
# }

# # NAT Gateway 생성 (Private Subnet 아웃바운드용)
# resource "aws_nat_gateway" "mcserver_nat" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public.id

#   # IGW가 생성된 후에 NAT Gateway 생성
#   depends_on = [aws_internet_gateway.mcserver_igw]
#   tags = {
#     Name = "${var.project_name}-natgw"
#   }
# }

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
     gateway_id = aws_internet_gateway.mcserver_igw.id #테스트
    # nat_gateway_id = aws_nat_gateway.mcserver_nat.id
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