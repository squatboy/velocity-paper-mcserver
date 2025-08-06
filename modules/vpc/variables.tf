variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "availability_zone" {
  description = "가용 영역"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public Subnet CIDR 블록 "
  type        = string
}

variable "private_subnet_cidr" {
  description = "Private Subnet CIDR 블록 "
  type        = string
}
