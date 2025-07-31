# =============================================================================
# CloudWatch 로그 그룹 설정
# =============================================================================

# Velocity 서버 로그 그룹
resource "aws_cloudwatch_log_group" "velocity_logs" {
  name              = "/minecraft/velocity"
  retention_in_days = 3  # 비용 절약을 위해 3일로 단축
  
  tags = {
    Name        = "${var.project_name}-velocity-logs"
    Environment = "production"
  }
}

# Paper 서버 로그 그룹
resource "aws_cloudwatch_log_group" "paper_logs" {
  name              = "/minecraft/paper"
  retention_in_days = 3  # 비용 절약을 위해 3일로 단축
  
  tags = {
    Name        = "${var.project_name}-paper-logs"
    Environment = "production"
  }
}

# 시스템 로그 그룹
resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/aws/ec2/system"
  retention_in_days = 7  # 시스템 로그는 7일 유지
  
  tags = {
    Name        = "${var.project_name}-system-logs"
    Environment = "production"
  }
}

# =============================================================================
# CloudWatch 알람 설정
# =============================================================================

# Velocity EC2 CPU 사용률 알람
resource "aws_cloudwatch_metric_alarm" "velocity_cpu_high" {
  alarm_name          = "${var.project_name}-velocity-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors velocity ec2 cpu utilization"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    InstanceId = var.velocity_instance_id
  }

  tags = {
    Name = "${var.project_name}-velocity-cpu-alarm"
  }
}

# Paper EC2 CPU 사용률 알람
resource "aws_cloudwatch_metric_alarm" "paper_cpu_high" {
  alarm_name          = "${var.project_name}-paper-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors paper ec2 cpu utilization"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    InstanceId = var.paper_instance_id
  }

  tags = {
    Name = "${var.project_name}-paper-cpu-alarm"
  }
}

# 메모리 사용률 알람 (CloudWatch Agent 필요)
resource "aws_cloudwatch_metric_alarm" "paper_memory_high" {
  alarm_name          = "${var.project_name}-paper-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors paper ec2 memory utilization"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    InstanceId = var.paper_instance_id
  }

  tags = {
    Name = "${var.project_name}-paper-memory-alarm"
  }
}

# 디스크 사용률 메트릭 (알림 없음, 모니터링만)
resource "aws_cloudwatch_metric_alarm" "paper_disk_monitoring" {
  alarm_name          = "${var.project_name}-paper-disk-monitoring"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = "600"
  statistic           = "Average"
  threshold           = "95"  # 95% 초과시에만 기록 (알림은 하지 않음)
  alarm_description   = "Disk usage monitoring for paper server"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.paper_instance_id
    device     = "/"
  }

  tags = {
    Name = "${var.project_name}-paper-disk-monitoring"
  }
}

# 네트워크 연결 상태 메트릭 (알림 없음, 모니터링만)
resource "aws_cloudwatch_metric_alarm" "paper_network_monitoring" {
  alarm_name          = "${var.project_name}-paper-network-monitoring"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "tcp_established"
  namespace           = "CWAgent"
  period              = "600"
  statistic           = "Average"
  threshold           = "1"  # 연결이 1개 미만일 때 (실제로는 거의 발생하지 않음)
  alarm_description   = "Network connection monitoring for paper server"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = var.paper_instance_id
  }

  tags = {
    Name = "${var.project_name}-paper-network-monitoring"
  }
}

# =============================================================================
# CloudWatch Agent 설정
# =============================================================================

# CloudWatch Agent 설정 파일 생성 (SSM Parameter로 저장)
resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name  = "/aws/cloudwatch-agent/${var.project_name}"
  type  = "String"
  value = jsonencode({
    agent = {
      metrics_collection_interval = 300
      run_as_user                 = "cwagent"
    }
    metrics = {
      namespace = "MinecraftServer"
      metrics_collected = {
        cpu = {
          measurement = ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"]  # 필수 메트릭만
          metrics_collection_interval = 600  # 10분으로 증가 (비용 절약)
          totalcpu = true
        }
        disk = {
          measurement = ["used_percent"]
          metrics_collection_interval = 600  # 10분으로 증가
          resources = ["/", "/mcserver"]  # 필요한 마운트포인트만
        }
        mem = {
          measurement = ["mem_used_percent"]
          metrics_collection_interval = 600  # 10분으로 증가
        }
        netstat = {
          measurement = ["tcp_established"]  # 필수 메트릭만
          metrics_collection_interval = 600  # 10분으로 증가
        }
      }
    }
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path = "/var/log/user-data.log"
              log_group_name = aws_cloudwatch_log_group.system_logs.name
              log_stream_name = "{instance_id}/user-data"
            },
            {
              file_path = "/mcserver/velocity/logs/latest.log"
              log_group_name = aws_cloudwatch_log_group.velocity_logs.name
              log_stream_name = "{instance_id}/velocity"
            },
            {
              file_path = "/mcserver/paper/logs/*.log"
              log_group_name = aws_cloudwatch_log_group.paper_logs.name
              log_stream_name = "{instance_id}/paper"
            }
          ]
        }
      }
    }
  })

  tags = {
    Name = "${var.project_name}-cloudwatch-agent-config"
  }
}
