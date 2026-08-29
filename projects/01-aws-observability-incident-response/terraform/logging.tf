resource "aws_cloudwatch_log_group" "nginx_access" {
  name              = "/portfolio/cloudops/${var.environment}/nginx-access"
  log_group_class   = "STANDARD"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "nginx_error" {
  name              = "/portfolio/cloudops/${var.environment}/nginx-error"
  log_group_class   = "STANDARD"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "cloud_init" {
  name              = "/portfolio/cloudops/${var.environment}/cloud-init"
  log_group_class   = "STANDARD"
  retention_in_days = 7
}
