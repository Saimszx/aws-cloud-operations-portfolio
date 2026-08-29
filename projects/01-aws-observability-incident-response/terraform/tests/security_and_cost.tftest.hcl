mock_provider "aws" {
  override_during = plan

  mock_data "aws_ssm_parameter" {
    defaults = {
      value = "ami-0123456789abcdef0"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "cwtestacct00"
      arn        = "arn:aws:iam::cwtestacct00:user/terraform-test"
      id         = "AIDATESTIDENTITY00000"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

run "security_and_cost_controls" {
  command = plan

  assert {
    condition     = aws_instance.web.metadata_options[0].http_tokens == "required"
    error_message = "The EC2 instance must require IMDSv2 tokens."
  }

  assert {
    condition     = aws_instance.web.root_block_device[0].encrypted
    error_message = "The EC2 root volume must be encrypted."
  }

  assert {
    condition     = aws_instance.web.root_block_device[0].delete_on_termination
    error_message = "The EC2 root volume must be deleted with the instance."
  }

  assert {
    condition     = aws_instance.web.root_block_device[0].volume_size <= 8
    error_message = "The lab root volume must not exceed the approved 8 GiB size."
  }

  assert {
    condition     = aws_instance.web.monitoring == false
    error_message = "Paid EC2 detailed monitoring must remain disabled for this lab."
  }

  assert {
    condition     = aws_iam_role.instance.permissions_boundary == "arn:aws:iam::cwtestacct00:policy/aws-observability-instance-boundary"
    error_message = "The EC2 role must use the permissions boundary created by the identity bootstrap."
  }

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.http.from_port == 80 &&
      aws_vpc_security_group_ingress_rule.http.to_port == 80 &&
      aws_vpc_security_group_ingress_rule.http.ip_protocol == "tcp"
    )
    error_message = "The public ingress rule must allow only TCP port 80."
  }

  assert {
    condition = alltrue([
      for group in [
        aws_cloudwatch_log_group.nginx_access,
        aws_cloudwatch_log_group.nginx_error,
        aws_cloudwatch_log_group.cloud_init
      ] : group.retention_in_days == 7 && group.log_group_class == "STANDARD"
    ])
    error_message = "Every log group must use Standard class with seven-day retention."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.high_cpu.threshold == 80 &&
      aws_cloudwatch_metric_alarm.high_cpu.period == 300 &&
      aws_cloudwatch_metric_alarm.high_cpu.evaluation_periods == 2 &&
      aws_cloudwatch_metric_alarm.high_cpu.datapoints_to_alarm == 2
    )
    error_message = "The high-CPU alarm must require two consecutive five-minute breaches above 80 percent."
  }
}
