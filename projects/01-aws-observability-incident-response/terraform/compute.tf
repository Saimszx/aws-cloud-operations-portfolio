data "aws_ssm_parameter" "amazon_linux_2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.this.name

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/../scripts/user-data.sh", {
    aws_region             = var.aws_region
    nginx_access_log_group = aws_cloudwatch_log_group.nginx_access.name
    nginx_error_log_group  = aws_cloudwatch_log_group.nginx_error.name
    cloud_init_log_group   = aws_cloudwatch_log_group.cloud_init.name
  })

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8

    tags = {
      Name = "${local.name_prefix}-root-volume"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm_core,
    aws_iam_role_policy.cloudwatch_agent,
    aws_route_table_association.public
  ]

  tags = {
    Name = "${local.name_prefix}-web"
  }
}
