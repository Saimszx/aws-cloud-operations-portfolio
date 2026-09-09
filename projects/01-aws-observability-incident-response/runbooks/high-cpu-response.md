# High CPU Incident Runbook

## Purpose

Use this runbook when the CloudWatch high-CPU alarm enters the `ALARM` state for the lab EC2 instance.

## Preconditions

- Confirm the instance belongs to this portfolio project by checking its tags.
- Determine whether the alert is caused by this approved test or an unexpected workload.
- Use AWS Systems Manager Session Manager; do not open SSH to the internet.
- Record the test start time before generating load.

## Controlled Test

Run the test only during the approved two-hour deployment window. On the instance,
start the bounded workload with:

```bash
portfolio-cpu-test 720
```

The command uses one worker per available CPU by default and stops after 720
seconds. It rejects durations below 60 seconds or above 900 seconds and rejects
more than four workers. Open a second Systems Manager session for investigation
while the test session remains active.

To reproduce the recorded run independently of the terminal connection, use a
transient systemd service instead of the foreground command above:

```bash
sudo systemd-run --unit=portfolio-cpu-incident --property=RuntimeMaxSec=780 /usr/local/bin/portfolio-cpu-test 720 2
systemctl status portfolio-cpu-incident --no-pager
```

After the test, check `systemctl show portfolio-cpu-incident -p ActiveState -p Result -p ExecMainStatus`.
An inactive service with a successful result means the bounded command finished.
To stop this service early, run `sudo systemctl stop portfolio-cpu-incident`.
Use either the foreground method or the systemd method, never both at once.

## Triage

1. Record the alarm name, start time, affected instance, and current metric value.
2. Review the CloudWatch dashboard for CPU, memory, network, and status-check signals.
3. Review recent application and cloud-init logs in CloudWatch Logs.
4. Open a Systems Manager session to the instance.
5. Inspect CPU consumers with read-only operating-system commands.
6. Confirm whether nginx is active and responding locally.

```bash
uptime
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 15
systemctl status nginx --no-pager
curl --fail --silent http://localhost/ > /dev/null && echo "nginx is responding"
```

## Containment and Recovery

1. Allow the bounded test to finish, or stop it using the method selected above (`Ctrl+C` for the foreground command, `systemctl stop` for the service).
2. Restart nginx only when evidence shows the service is unhealthy.
3. Avoid rebooting until lower-impact recovery actions have been evaluated.
4. Confirm the website responds and operational metrics return to normal.
5. Wait for the CloudWatch alarm to leave the `ALARM` state.

## Evidence

- Alarm history
- Dashboard before and after recovery
- Relevant log events
- Process or service status output
- Recovery timestamp

## Closure

- Complete the incident report.
- Document the root cause, contributing factors, and preventive action.
- Remove all temporary incident-generation processes.
- Destroy the lab after project evidence is complete.
