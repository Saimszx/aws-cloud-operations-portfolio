# Architecture Design Decisions

## Public Subnet Without SSH

The temporary web workload uses a public subnet so it can reach package repositories and AWS service endpoints without a NAT gateway. A NAT gateway would add unnecessary cost for this learning objective. The security group allows HTTP but has no inbound SSH rule.

Administrative access uses AWS Systems Manager Session Manager. The EC2 instance role includes `AmazonSSMManagedInstanceCore`, and Instance Metadata Service Version 2 is required.

## Infrastructure as Code

Terraform creates the complete environment: networking, IAM instance profile, log groups, EC2 workload, SNS topic, alarms, and dashboard. The selected AWS provider version is recorded in `.terraform.lock.hcl` for reproducibility.

Terraform state is local for the first lab and is excluded from Git. A later project will introduce a secure remote-state design after the required state-locking and recovery concepts have been documented.

## Observability

The design uses two signal sources:

- Native EC2 metrics for CPU, network traffic, and status checks
- CloudWatch Agent metrics and logs for memory, nginx, and cloud-init

Log groups are created by Terraform with seven-day retention. The instance can write only to the project log groups and the `CWAgent` metric namespace.

The operations dashboard starts with alarm panels so the operator can see state
before investigating individual metrics. It then presents CPU, EC2 status,
memory, network traffic, and recent nginx requests in one eight-hour view. Saved
Logs Insights queries provide deeper investigation without making the dashboard
too crowded.

Both alarms notify on transitions into `ALARM` and back into `OK`. Recovery
notifications close the operational loop and provide an exact timestamp for the
incident report.

## Cost Decisions

- Default instance type: `t3.micro`, subject to a current eligibility check before deployment
- Root volume: encrypted 8 GiB `gp3`
- No NAT gateway, load balancer, elastic IP, database, or Kubernetes control plane
- Five-minute custom metric interval to avoid unnecessary high-resolution metrics
- Basic EC2 monitoring instead of paid one-minute detailed monitoring
- Seven-day log retention
- Standard log class so Logs Insights supports the full investigation workflow
- Root-volume deletion is explicit when the instance is terminated
- Temporary deployment followed by Terraform teardown
- Two-hour maximum deployment window
- Conservative per-run ceiling of USD 0.60 before taxes or unexpected transfer

See the project [cost estimate](../COST_ESTIMATE.md) for the calculation and
pricing assumptions.

## SNS Encryption Decision

The lab alarm topic carries only operational state changes and no sensitive
payload. The AWS managed `alias/aws/sns` key cannot be used for this integration
because CloudWatch alarms cannot receive the required permissions in an AWS
managed key policy. A compatible customer managed KMS key would add cost and
remain pending deletion after the short-lived lab is removed.

The lab therefore records an explicit exception and leaves the temporary topic
unencrypted. A production implementation with sensitive alert content would use
a customer managed KMS key with a policy scoped to CloudWatch.

## Known Tradeoffs

- A public IPv4 address is needed for the temporary HTTP demonstration and may consume credits.
- HTTP is acceptable only for this disposable lab page. A production design would add HTTPS through a managed entry point.
- A single instance is intentionally not highly available. Availability and load balancing belong in a later project.
- Email notification is optional because every SNS email endpoint requires explicit confirmation.
- Local Terraform state may contain the optional email endpoint and must remain untracked and protected.
