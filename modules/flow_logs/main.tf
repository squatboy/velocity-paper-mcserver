# =============================================================================
# VPC Flow Logs 설정
# =============================================================================

# VPC Flow Logs를 위한 S3 버킷
resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket = "${var.project_name}-vpc-flow-logs-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "${var.project_name}-vpc-flow-logs"
    Purpose     = "VPC Flow Logs Storage"
    Environment = "production"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 버킷 정책 설정
resource "aws_s3_bucket_policy" "vpc_flow_logs_policy" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.vpc_flow_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.vpc_flow_logs.arn
      }
    ]
  })
}

# VPC Flow Logs 활성화 (S3로 전송)
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_s3_bucket.vpc_flow_logs.arn
  traffic_type    = "REJECT"
  vpc_id          = var.vpc_id
  
  tags = {
    Name = "${var.project_name}-vpc-flow-log"
  }
}

# VPC Flow Logs를 위한 IAM Role
resource "aws_iam_role" "flow_log" {
  name = "${var.project_name}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_log" {
  name = "${var.project_name}-flow-log-policy"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
