resource "aws_sns_topic" "operations" {
  name = "${local.name_prefix}-operations"
}

resource "aws_sns_topic_subscription" "email" {
  count = var.notification_email == null ? 0 : 1

  topic_arn = aws_sns_topic.operations.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name_prefix}-high-cpu"
  alarm_description   = "CPU utilization exceeded 80 percent for ten minutes."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.web.id
  }

  alarm_actions = [aws_sns_topic.operations.arn]
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "${local.name_prefix}-status-check-failed"
  alarm_description   = "The EC2 instance failed a system or instance status check."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.web.id
  }

  alarm_actions = [aws_sns_topic.operations.arn]
}

resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "${local.name_prefix}-operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "EC2 CPU utilization"
          view    = "timeSeries"
          region  = var.aws_region
          stat    = "Average"
          period  = 300
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web.id]]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EC2 status checks"
          view   = "timeSeries"
          region = var.aws_region
          stat   = "Maximum"
          period = 60
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.web.id],
            [".", "StatusCheckFailed_Instance", ".", "."],
            [".", "StatusCheckFailed_System", ".", "."]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Memory utilization"
          view   = "timeSeries"
          region = var.aws_region
          stat   = "Average"
          period = 300
          metrics = [[
            "CWAgent",
            "mem_used_percent",
            "InstanceId",
            aws_instance.web.id
          ]]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Network traffic"
          view   = "timeSeries"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.web.id],
            [".", "NetworkOut", ".", "."]
          ]
        }
      }
    ]
  })
}
