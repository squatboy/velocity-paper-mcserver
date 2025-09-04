# =================
# VPC 모듈 호출
# =================
module "vpc" {
  source = "./modules/vpc"

  project_name        = var.project_name
  aws_region          = var.aws_region
  vpc_cidr            = var.vpc_cidr
  availability_zone   = var.availability_zone
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}

# =================
# Security 모듈 호출
# =================
module "security" {
  source = "./modules/security"

  # 필수 변수들
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  admin_ip     = var.admin_ip
  # VPC 모듈 완료 후 실행
  depends_on = [module.vpc]
}

# =================
# IAM 모듈 호출
# =================
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
}

# =================
# EBS 모듈 호출
# =================
module "ebs" {
  source = "./modules/ebs"

  project_name      = var.project_name
  availability_zone = var.availability_zone
  paper_ebs_size    = var.paper_ebs_size
  velocity_ebs_size = var.velocity_ebs_size
}

# =================
# EC2 모듈 호출
# =================
module "ec2" {
  source = "./modules/ec2"

  project_name               = var.project_name
  vpc_id                     = module.vpc.vpc_id
  public_subnet_id           = module.vpc.public_subnet_id
  private_subnet_id          = module.vpc.private_subnet_id
  availability_zone          = module.vpc.availability_zone
  velocity_security_group_id = module.security.velocity_security_group_id
  paper_security_group_id    = module.security.paper_security_group_id
  iam_instance_profile_name  = module.iam.ec2_instance_profile_name
  paper_ebs_volume_id        = module.ebs.paper_ebs_volume_id
  velocity_ebs_volume_id     = module.ebs.velocity_ebs_volume_id
  velocity_instance_type     = var.velocity_instance_type
  paper_instance_type        = var.paper_instance_type
  key_name                   = var.key_name
  grafana_admin_username     = var.grafana_admin_username
  grafana_admin_password     = var.grafana_admin_password
  prometheus_scrape_interval = var.prometheus_scrape_interval
  prometheus_retention       = var.prometheus_retention

  # 모든 의존성 모듈이 완료된 후 실행
  depends_on = [module.vpc, module.security, module.iam, module.ebs]
}

# =============================================================================
# DLM 백업 모듈 호출
# =============================================================================
module "dlm" {
  source = "./modules/dlm"

  project_name = var.project_name
  dlm_role_arn = module.iam.dlm_role_arn

  depends_on = [module.iam]
}


# =============================================================================
# 모니터링 및 알림 모듈 호출
# =============================================================================



# =================
# SNS, Lambda 
# =================
module "sns" {
  source = "./modules/sns"

  project_name = var.project_name
}

module "lambda" {
  source = "./modules/lambda"

  project_name        = var.project_name
  discord_webhook_url = var.discord_webhook_url

}

# SNS Topic에 Lambda 구독 추가
resource "aws_sns_topic_subscription" "lambda_alerts" {
  topic_arn = module.sns.sns_topic_arn
  protocol  = "lambda"
  endpoint  = module.lambda.lambda_arn
}

# Lambda 함수에 SNS 호출 권한 부여
resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = module.sns.sns_topic_arn
}

# =================
# CloudWatch 모듈
# =================
module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name         = var.project_name
  velocity_instance_id = module.ec2.ec2_instances_info.velocity.id
  paper_instance_id    = module.ec2.ec2_instances_info.paper.id
  sns_topic_arn        = module.sns.sns_topic_arn

  # EC2 및 SNS, Lambda 모듈 완료 후 실행
  depends_on = [module.ec2, module.sns, module.lambda]
}
