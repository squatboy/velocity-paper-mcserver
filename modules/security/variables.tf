variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (VPC 모듈에서 전달받음)"
  type        = string
}

variable "admin_ip" {
  description = "운영자 고정 IP (Grafana UI 제한)"
  type        = string
}
