# High CPU Incident Runbook

## Purpose

Use this runbook when the CloudWatch high-CPU alarm enters the `ALARM` state for the lab EC2 instance.

## Preconditions

- Confirm the instance belongs to this portfolio project by checking its tags.
- Confirm the alert is not caused by an approved test.
- Use AWS Systems Manager Session Manager; do not open SSH to the internet.

## Triage

1. Record the alarm name, start time, affected instance, and current metric value.
2. Review the CloudWatch dashboard for CPU, memory, network, and status-check signals.
3. Review recent application and cloud-init logs in CloudWatch Logs.
4. Open a Systems Manager session to the instance.
5. Inspect CPU consumers with read-only operating-system commands.
6. Confirm whether nginx is active and responding locally.

## Containment and Recovery

1. Stop only the confirmed test workload or faulty process.
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
