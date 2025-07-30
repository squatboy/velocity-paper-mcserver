# =============================================================================
# Core Infrastructure Variables
# =============================================================================

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "mc-server"
}

# =============================================================================
# VPC Module Variables
# =============================================================================

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone" {
  description = "가용 영역"
  type        = string
  default     = "ap-northeast-2a"
}

variable "public_subnet_cidr" {
  description = "Public Subnet CIDR 블록"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Private Subnet CIDR 블록"
  type        = string
  default     = "10.0.11.0/24"
}

# =============================================================================
# EC2 Module Variables
# =============================================================================

variable "velocity_instance_type" {
  description = "Velocity Proxy EC2 인스턴스 타입"
  type        = string
}

variable "paper_instance_type" {
  description = "Paper Server EC2 인스턴스 타입"
  type        = string
}

variable "key_name" {
  description = "EC2 인스턴스에 사용할 키페어 이름"
  type        = string
  default     = "mcserver"
}

# =============================================================================
# EBS Module Variables
# =============================================================================

variable "paper_ebs_size" {
  description = "PaperMC 서버용 EBS 볼륨 크기 (GB)"
  type        = number
  default     = 20
}

variable "velocity_ebs_size" {
  description = "Velocity 프록시용 EBS 볼륨 크기 (GB)"
  type        = number
  default     = 1
}

# =============================================================================
# Monitoring Module Variables
# =============================================================================

variable "discord_webhook_url" {
  description = "Discord 웹훅 URL"
  type        = string
  sensitive   = true
}
