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

cat > /usr/local/bin/portfolio-cpu-test <<'CPU_TEST'
#!/bin/bash
set -euo pipefail

duration_seconds="$${1:-720}"
worker_count="$${2:-$(nproc)}"

if ! [[ "$duration_seconds" =~ ^[0-9]+$ ]] || ((duration_seconds < 60 || duration_seconds > 900)); then
  echo "Duration must be an integer from 60 through 900 seconds." >&2
  exit 2
fi

if ! [[ "$worker_count" =~ ^[0-9]+$ ]] || ((worker_count < 1 || worker_count > 4)); then
  echo "Worker count must be an integer from 1 through 4." >&2
  exit 2
fi

pids=()
cleanup() {
  for pid in "$${pids[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

logger -t portfolio-cpu-test "Starting bounded CPU test: duration=$${duration_seconds}s workers=$${worker_count}"
echo "Starting $${worker_count} CPU workers for $${duration_seconds} seconds."

for ((worker = 1; worker <= worker_count; worker++)); do
  bash -c 'end=$((SECONDS + $1)); while ((SECONDS < end)); do :; done' _ "$duration_seconds" &
  pids+=("$!")
done

wait
logger -t portfolio-cpu-test "Completed bounded CPU test"
echo "CPU test completed."
CPU_TEST

chmod 0755 /usr/local/bin/portfolio-cpu-test

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
