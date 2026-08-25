data "aws_iam_policy_document" "ec2_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${local.name_prefix}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "cloudwatch_agent" {
  statement {
    sid    = "WritePortfolioLogStreams"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.nginx_access.arn}:*",
      "${aws_cloudwatch_log_group.nginx_error.arn}:*",
      "${aws_cloudwatch_log_group.cloud_init.arn}:*"
    ]
  }

  statement {
    sid       = "PublishCloudWatchAgentMetrics"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CWAgent"]
    }
  }
}

resource "aws_iam_role_policy" "cloudwatch_agent" {
  name   = "${local.name_prefix}-cloudwatch-agent"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.cloudwatch_agent.json
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.instance.name
}
