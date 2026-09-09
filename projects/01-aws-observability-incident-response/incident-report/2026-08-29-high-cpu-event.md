# Incident Report: Controlled High CPU Event

## Summary

- Date: August 29, 2026
- Environment: Temporary `lab` environment in `us-east-2`
- Detection source: Amazon CloudWatch high-CPU alarm with Amazon SNS actions
- Severity: Low, controlled exercise with no customer workload
- End-to-end duration: 14 minutes 13 seconds
- Time in `ALARM`: 6 minutes
- Customer impact: None; local and public HTTP checks continued to return success

## Timeline

| Time (UTC) | Event |
| --- | --- |
| 22:23:33 | The bounded 720-second CPU simulation started through AWS Systems Manager Session Manager. The alarm was initially `OK`. |
| 22:24:00 | Initial triage found two CPU workers near 100 percent. nginx, SSM Agent, and CloudWatch Agent were active. |
| 22:31:46 | CloudWatch changed the high-CPU alarm from `OK` to `ALARM`. |
| 22:32:26 | Triage during `ALARM` confirmed both workers near 99.8 percent and verified successful local and public HTTP responses. |
| 22:35:33 | The bounded test reached its configured 720-second limit. |
| 22:36:23 | Session Manager verification showed the transient systemd unit inactive with `Result=success` and `ExecMainStatus=0`. All required services remained active. |
| 22:37:46 | CloudWatch returned the alarm to `OK` after CPU utilization fell below the threshold. |
| 22:39:49 | Terraform teardown and the zero-resource verification completed. |

## Detection

The alarm monitored the `AWS/EC2` `CPUUtilization` metric with an average
statistic over 300-second periods. It required two of two consecutive datapoints
above 80 percent and treated missing data as not breaching. Both `ALARM` and
`OK` state changes targeted the project SNS topic. No email subscription was
configured for this run. The retained evidence proves alarm state changes and
configured SNS targets, but does not independently prove successful SNS
publication or delivery to a recipient.

The first complete high-load datapoint averaged approximately 100 percent. The
alarm entered `ALARM` 8 minutes 13 seconds after the test began, which was
consistent with two aligned CloudWatch evaluation periods.

## Root Cause

The event was intentionally caused by `/usr/local/bin/portfolio-cpu-test`. The
script started one bounded busy-loop worker for each of the two available CPUs
on the `t3.micro` instance. A transient systemd unit launched the command with a
720-second limit, so the workload could not continue indefinitely if the
administrative session disconnected.

## Triage and Resolution

All administration used Session Manager; port 22 was never opened and no SSH
key existed. The operator inspected load averages, the highest CPU consumers,
service state, and the local HTTP endpoint. Evidence showed CPU saturation but
no nginx, SSM Agent, CloudWatch Agent, EC2 status-check, or HTTP failure.

Because the workload was an approved bounded test and the service remained
healthy, the lowest-risk response was to let it finish. No reboot, instance
replacement, or nginx restart was performed. After the systemd unit exited
successfully, CPU utilization declined and CloudWatch returned the alarm to
`OK` automatically.

## Sanitized Evidence

- Terraform clean apply: 20 resources added, 0 changed, 0 destroyed
- Instance controls: IMDSv2 required, encrypted 8-GiB `gp3` volume, detailed monitoring disabled
- Network controls: one TCP/80 ingress rule and no TCP/22 ingress
- IAM control: the EC2 role used `aws-observability-instance-boundary`
- Runtime readiness: SSM `Online`, HTTP successful, three log streams present, and the `CWAgent` memory metric present
- During alarm: two CPU workers near 99.8 percent; nginx and both management agents active
- Logs Insights: five HTTP `200` requests and zero cloud-init events matching `error`, `failed`, or `exception`
- Recovery: test unit completed successfully and alarm returned to `OK`
- Terraform clean destroy: 0 added, 0 changed, 20 destroyed
- Post-teardown verification: zero managed state entries, active project instances, project VPCs, project log groups, project alarms, and project dashboards

The consolidated evidence is recorded in
[the validation summary](../evidence/2026-08-29-validation-summary.md). Raw
screenshots, account identifiers, public IP addresses, session identifiers, and
temporary credentials are intentionally excluded.

## Lessons Learned

- What worked well: The bounded test, Session Manager access, dashboard,
  CloudWatch Agent, alarm configuration, service checks, and teardown procedure
  all behaved as designed.
- What could be improved: The first provider-backed apply exposed one missing
  EC2 read permission, and the evidence workflow exposed one missing CloudWatch
  alarm-history read permission.
- Corrective action: Add only
  `ec2:DescribeInstanceCreditSpecifications` and
  `cloudwatch:DescribeAlarmHistory` to the scoped deployment role, validate the
  CloudFormation template, and review each stack change set before execution.
- Preventive action: Keep mocked policy tests in CI and repeat a short live
  integration run after changes to provider versions or deployment-role
  permissions.

## Resource Teardown

- Terraform destroy completed: Yes, at 22:39:49 UTC
- Terraform state verified empty: Yes
- AWS service-level leftover checks: All checked counts were zero
- Monthly cost guardrail: The existing USD 1.00 AWS Budget remained active
