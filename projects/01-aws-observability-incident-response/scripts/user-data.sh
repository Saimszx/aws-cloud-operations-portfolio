#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y nginx amazon-cloudwatch-agent

cat > /usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>AWS Cloud Operations Lab</title>
  </head>
  <body>
    <h1>AWS Cloud Operations Lab</h1>
    <p>This temporary workload is managed with Terraform and monitored with Amazon CloudWatch.</p>
  </body>
</html>
HTML

systemctl enable --now nginx
systemctl enable --now amazon-ssm-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
{
  "agent": {
    "metrics_collection_interval": 300,
    "region": "${aws_region}"
  },
  "metrics": {
    "namespace": "CWAgent",
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 300
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "${nginx_access_log_group}",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "${nginx_error_log_group}",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "${cloud_init_log_group}",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
CWCONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
