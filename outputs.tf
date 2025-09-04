output "vpc_id" {
  description = "생성된 VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR 블록"
  value       = module.vpc.vpc_cidr_block
}


output "ec2_instances_info" {
  description = "EC2 인스턴스들의 상세 정보"
  value       = module.ec2.ec2_instances_info
}

output "security_groups_info" {
  description = "생성된 보안 그룹들의 상세 정보"
  value       = module.security.security_groups_info
}

# =============================================================================
# IAM Module Outputs
# =============================================================================

output "iam_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = module.iam.ec2_role_arn
}

output "iam_instance_profile_name" {
  description = "EC2 Instance Profile 이름"
  value       = module.iam.ec2_instance_profile_name
}

# =============================================================================
# EBS Module Outputs
# =============================================================================

output "paper_ebs_volume_id" {
  description = "Paper 서버용 EBS 볼륨 ID"
  value       = module.ebs.paper_ebs_volume_id
}

output "velocity_ebs_volume_id" {
  description = "Velocity 프록시용 EBS 볼륨 ID"
  value       = module.ebs.velocity_ebs_volume_id
}

# =============================================================================
# EC2 Module Outputs
# =============================================================================

output "velocity_ec2_public_ip" {
  description = "Velocity Proxy EC2 Public IP (접속용)"
  value       = module.ec2.ec2_instances_info.velocity.public_ip
}

output "velocity_ec2_info" {
  description = "Velocity Proxy EC2 상세 정보"
  value       = module.ec2.ec2_instances_info.velocity
}

output "paper_ec2_info" {
  description = "Paper Server EC2 상세 정보"
  value       = module.ec2.ec2_instances_info.paper
}

output "ec2_instances_summary" {
  description = "모든 EC2 인스턴스 요약 정보"
  value       = module.ec2.ec2_instances_info
}



# =============================================================================
# SNS Module Outputs
# =============================================================================

output "sns_topic_arn" {
  description = "모니터링 알림용 SNS Topic ARN"
  value       = module.sns.sns_topic_arn
}

output "sns_topic_name" {
  description = "SNS Topic 이름"
  value       = module.sns.sns_topic_name
}

# =============================================================================
# CloudWatch Module Outputs
# =============================================================================

output "cloudwatch_agent_config_parameter" {
  description = "CloudWatch Agent 설정 SSM Parameter"
  value       = module.cloudwatch.cloudwatch_agent_config_parameter
}

output "cloudwatch_alarm_names" {
  description = "CloudWatch 알람 이름들"
  value       = module.cloudwatch.alarm_names
}

# =============================================================================
# 통합 모니터링 정보
# =============================================================================

output "monitoring_info" {
  description = "모니터링 시스템 전체 정보"
  value = {
    sns_topic_arn           = module.sns.sns_topic_arn
    cloudwatch_agent_config = module.cloudwatch.cloudwatch_agent_config_parameter
    cloudwatch_alarms       = module.cloudwatch.alarm_names
    grafana_url             = "http://${module.ec2.ec2_instances_info.velocity.public_ip}:3000"
    grafana_admin_user      = var.grafana_admin_username
    restricted_admin_ip     = var.admin_ip
    prometheus_scrape_interval = var.prometheus_scrape_interval
    prometheus_retention       = var.prometheus_retention
  }
}

output "grafana_url" {
  description = "Grafana 접속 URL (보안그룹에서 admin_ip만 허용)"
  value       = "http://${module.ec2.ec2_instances_info.velocity.public_ip}:3000"
}
