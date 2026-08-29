# Cost Estimate and Deployment Limit

## Purpose

This estimate defines the financial boundary for one controlled deployment of
the lab. It is intentionally conservative so the operator does not depend on
Free Tier allowances or promotional credits.

## Assumptions

- Pricing snapshot date: August 29, 2026
- AWS Region: US East (Ohio), `us-east-2`
- Maximum deployment window: two hours
- One Linux `t3.micro` EC2 instance
- One encrypted 8 GiB `gp3` root volume
- One in-use public IPv4 address
- Two standard-resolution CloudWatch alarms
- One CloudWatch Agent custom metric
- No more than 0.01 GB of CloudWatch Logs ingestion
- Minimal HTTP traffic and no large data transfer

## Conservative Estimate

| Component | Pricing input | Estimated charge |
| --- | ---: | ---: |
| EC2 compute | USD 0.0104 per hour for 2 hours | USD 0.0208 |
| Public IPv4 | USD 0.005 per hour for 2 hours | USD 0.0100 |
| 8 GiB `gp3` storage | USD 0.08 per GB-month, prorated over 730 hours | USD 0.0018 |
| Two standard alarms | USD 0.10 per alarm metric-month | USD 0.2000 |
| One custom metric | USD 0.30 per metric-month | USD 0.3000 |
| 0.01 GB log ingestion | USD 0.50 per GB | USD 0.0050 |
| **Conservative total** | Rounded from USD 0.5376 | **USD 0.54** |

The alarm and custom-metric rows assume a full metric-month even though the lab
is temporary. This creates a cautious upper estimate. Actual charges may be
lower because of prorating, Free Tier allowances, or account credits, but those
benefits are not treated as guaranteed.

## Guardrails

- Operational cost ceiling for one run: USD 0.60
- AWS monthly budget: USD 1.00
- Actual-spend notification threshold: greater than USD 0.01
- Stop and investigate if any resource not listed in the Terraform plan appears.
- Stop and destroy the lab if the test cannot be completed within two hours.
- Never leave an EC2 instance, EBS volume, public IPv4 address, alarm, dashboard,
  log group, or SNS topic running after the evidence is captured.

## Encryption Tradeoff for SNS

The SNS topic does not contain passwords, tokens, customer data, or application
payloads. It carries only lab alarm state notifications. A CloudWatch alarm
cannot publish to a topic encrypted with the AWS managed `alias/aws/sns` key.
A compatible design requires a customer managed KMS key and additional key
policy permissions. That key adds cost and cannot be deleted immediately because
KMS enforces a waiting period.

For this short-lived, non-sensitive lab, the project keeps the topic unencrypted
and records the exception here. A production environment with sensitive alert
content would use a customer managed KMS key and grant
`cloudwatch.amazonaws.com` only the required KMS permissions.

## Pricing Sources

The rates above were checked through the AWS Price List API. Recheck them before
each future deployment because prices and Free Tier rules can change.

- [Amazon EC2 pricing](https://aws.amazon.com/ec2/pricing/on-demand/)
- [Amazon VPC pricing](https://aws.amazon.com/vpc/pricing/)
- [Amazon CloudWatch pricing](https://aws.amazon.com/cloudwatch/pricing/)
- [AWS Pricing Calculator](https://calculator.aws/)
