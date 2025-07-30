output "lambda_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.discord_notifier.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.discord_notifier.function_name
}