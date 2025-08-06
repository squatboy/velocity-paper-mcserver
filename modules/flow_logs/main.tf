# =============================================================================
# VPC Flow Logs 설정
# =============================================================================

# VPC Flow Logs를 위한 S3 버킷
resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket = "${var.project_name}-vpc-flow-logs"
  
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

# S3 버킷 수명 주기 정책 (30일 후 로그 삭제)
resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs_lifecycle" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  rule {
    id     = "log-expiration"
    status = "Enabled"

    filter {
      prefix = "mcserver-flow-logs/"
    }

    expiration {
      days = 30
    }
  }
}

# VPC Flow Logs 활성화 (S3로 전송)
resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_s3_bucket.vpc_flow_logs.arn
  log_destination_type = "s3"
  traffic_type         = "REJECT"
  vpc_id               = var.vpc_id
  
  tags = {
    Name = "${var.project_name}-vpc-flow-log"
  }
}
