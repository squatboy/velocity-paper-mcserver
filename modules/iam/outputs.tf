output "ec2_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_role_name" {
  description = "EC2 IAM Role 이름"
  value       = aws_iam_role.ec2_role.name
}

output "ec2_instance_profile_name" {
  description = "EC2 Instance Profile 이름"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_instance_profile_arn" {

  description = "EC2 Instance Profile ARN"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "dlm_role_arn" {
    description = "DLM Service IAM Role ARN"
    value       = aws_iam_role.dlm_role.arn
}