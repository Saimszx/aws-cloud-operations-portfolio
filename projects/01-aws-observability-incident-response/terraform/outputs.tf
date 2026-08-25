output "instance_id" {
  description = "EC2 instance identifier."
  value       = aws_instance.web.id
}

output "public_url" {
  description = "Temporary HTTP endpoint for the demonstration workload."
  value       = "http://${aws_instance.web.public_ip}"
}

output "systems_manager_session_command" {
  description = "Command that can open a secure session after AWS CLI authentication is configured."
  value       = "aws ssm start-session --target ${aws_instance.web.id} --region ${var.aws_region}"
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch operations dashboard name."
  value       = aws_cloudwatch_dashboard.operations.dashboard_name
}

output "sns_topic_arn" {
  description = "SNS topic used by operational alarms."
  value       = aws_sns_topic.operations.arn
}
