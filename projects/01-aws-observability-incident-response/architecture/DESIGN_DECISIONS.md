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

## Cost Decisions

- Default instance type: `t3.micro`, subject to a current eligibility check before deployment
- Root volume: encrypted 8 GiB `gp3`
- No NAT gateway, load balancer, elastic IP, database, or Kubernetes control plane
- Five-minute custom metric interval to avoid unnecessary high-resolution metrics
- Seven-day log retention
- Temporary deployment followed by Terraform teardown

## Known Tradeoffs

- A public IPv4 address is needed for the temporary HTTP demonstration and may consume credits.
- HTTP is acceptable only for this disposable lab page. A production design would add HTTPS through a managed entry point.
- A single instance is intentionally not highly available. Availability and load balancing belong in a later project.
- Email notification is optional because every SNS email endpoint requires explicit confirmation.
