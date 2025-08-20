

output "cloudwatch_agent_config_parameter" {
  description = "SSM Parameter name for CloudWatch Agent configuration"
  value       = aws_ssm_parameter.cloudwatch_agent_config.name
}

output "alarm_names" {
  description = "CloudWatch alarm names"
  value = {
    velocity_cpu_high       = aws_cloudwatch_metric_alarm.velocity_cpu_high.alarm_name
    paper_cpu_high         = aws_cloudwatch_metric_alarm.paper_cpu_high.alarm_name
    paper_memory_high      = aws_cloudwatch_metric_alarm.paper_memory_high.alarm_name
    paper_disk_monitoring  = aws_cloudwatch_metric_alarm.paper_disk_monitoring.alarm_name
    paper_network_monitoring = aws_cloudwatch_metric_alarm.paper_network_monitoring.alarm_name
  }
}
