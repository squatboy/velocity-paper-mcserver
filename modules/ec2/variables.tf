variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public Subnet ID (Proxy EC2용)"
  type        = string
}

variable "private_subnet_id" {
  description = "Private Subnet ID (Paper EC2용)"
  type        = string
}

variable "availability_zone" {
  description = "가용 영역"
  type        = string
  
}

variable "velocity_security_group_id" {
  description = "Velocity 보안 그룹 ID"
  type        = string
}

variable "paper_security_group_id" {
  description = "Paper 보안 그룹 ID"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "EC2 Instance Profile 이름"
  type        = string
}

variable "paper_ebs_volume_id" {
  description = "Paper EC2에 연결할 EBS 볼륨 ID"
  type        = string
}

variable "velocity_ebs_volume_id" {
  description = "Velocity EC2에 연결할 EBS 볼륨 ID"
  type        = string
}

variable "velocity_instance_type" {
  description = "Velocity EC2 인스턴스 타입"
  type        = string
}

variable "paper_instance_type" {
  description = "Paper EC2 인스턴스 타입"
  type        = string
}

variable "key_name" {
  description = "EC2 인스턴스에 사용할 키페어 이름"
  type        = string
}

variable "grafana_admin_username" {
  description = "Grafana 관리자 유저명"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana 관리자 비밀번호"
  type        = string
  sensitive   = true
}

variable "prometheus_scrape_interval" {
  description = "Prometheus scrape interval"
  type        = string
}

variable "prometheus_retention" {
  description = "Prometheus 데이터 보존 기간"
  type        = string
}
