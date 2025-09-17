# =============================================================================
# Core Infrastructure Variables
# =============================================================================

variable "aws_region" {
  description = "AWS 리전"
  type        = string
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
}

variable "availability_zone" {
  description = "가용 영역"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public Subnet CIDR 블록"
  type        = string
}

variable "private_subnet_cidr" {
  description = "Private Subnet CIDR 블록"
  type        = string
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
}

# =============================================================================
# EBS Module Variables
# =============================================================================

variable "paper_ebs_size" {
  description = "PaperMC 서버용 EBS 볼륨 크기 (GB)"
  type        = number
}

variable "velocity_ebs_size" {
  description = "Velocity 프록시용 EBS 볼륨 크기 (GB)"
  type        = number
}

# =============================================================================
# Monitoring Module Variables
# =============================================================================

variable "discord_webhook_url" {
  description = "Discord 웹훅 URL"
  type        = string
  sensitive   = true
}

# =============================================================================
# Observability (Prometheus & Grafana) Variables
# =============================================================================

variable "admin_ip" {
  description = "운영자가 접속할 고정 IP (Grafana UI 제한용 CIDR)"
  type        = string
  sensitive   = true
}

variable "grafana_admin_username" {
  description = "Grafana 관리자 유저명"
  type        = string
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Grafana 관리자 비밀번호"
  type        = string
  sensitive   = true
}

variable "prometheus_scrape_interval" {
  description = "Prometheus 전역 scrape interval"
  type        = string
}

variable "prometheus_retention" {
  description = "Prometheus TSDB 보존 기간"
  type        = string
}
