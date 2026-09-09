# Validation Summary - August 29, 2026

## Purpose

This file provides sanitized, text-based evidence for the completed AWS
observability and incident-response lab. It records outcomes without exposing an
AWS account ID, public IP address, resource identifier, browser session, email
address, token, or credential.

## Identity and Tooling

- Human CLI identity verified as `aws-portfolio-admin`, not the AWS account root user
- Terraform and operational commands verified as the assumed role `aws-portfolio-deployer`
- MFA was required by the role trust policy
- No IAM user access keys were created
- AWS CLI temporary login credentials were exposed to the Terraform AWS provider through a `credential_process` bridge
- Session Manager plugin version `1.2.835.0` was installed from the official AWS package

## Infrastructure Validation

| Check | Result |
| --- | --- |
| Terraform format, initialization, and validation | Pass |
| Mocked Terraform security and cost test | 1 passed, 0 failed |
| CloudFormation linting | 0 errors, 0 warnings, 0 informational findings |
| CloudFormation Guard | 7 rules passed |
| Reviewed Terraform plan | 20 create, 0 update, 0 delete |
| Clean Terraform apply | 20 added, 0 changed, 0 destroyed |
| Region | `us-east-2` |
| EC2 instance type | `t3.micro` |
| Root volume | Encrypted `gp3`, 8 GiB, delete on termination |
| Instance metadata | IMDSv2 required |
| EC2 detailed monitoring | Disabled |
| Public ingress | TCP port 80 only |
| SSH ingress | None |
| EC2 permissions boundary | Attached |

## Runtime and Observability

| Check | Result |
| --- | --- |
| Systems Manager managed-node status | Online |
| Public and local HTTP response | Success |
| nginx access, nginx error, and cloud-init log streams | Present |
| `CWAgent` memory metric | Present |
| CloudWatch alarms | Two, with actions enabled |
| CloudWatch dashboard | Available |
| Logs Insights HTTP distribution | Five responses with status `200` |
| Logs Insights cloud-init error search | Zero matching events |

## Controlled Incident

- Simulation start: `2026-08-29T22:23:33Z`
- Workload: Two bounded CPU workers for 720 seconds
- Initial alarm state: `OK`
- High-load metric: Approximately 100 percent average CPU
- Alarm entered `ALARM`: `2026-08-29T22:31:46Z`
- HTTP availability during `ALARM`: Successful
- Test process result: Success, exit status 0
- Alarm returned to `OK`: `2026-08-29T22:37:46Z`
- End-to-end incident duration: 14 minutes 13 seconds

## Troubleshooting Evidence

The first live apply identified that the Terraform AWS provider reads EC2 burst
credit configuration after instance creation. The deployment role did not yet
allow `ec2:DescribeInstanceCreditSpecifications`, so Terraform stopped with an
authorization error. The partial environment was removed with Terraform, the
CloudFormation role policy was updated through a reviewed change set, and the
clean deployment then completed successfully.

The incident evidence workflow also showed that
`cloudwatch:DescribeAlarmHistory` was required to retrieve formal alarm history.
That read-only action was added to the CloudFormation template as a follow-up.
These corrections preserve least privilege by adding only the operations that
were observed and justified.

## Teardown Evidence

- Clean Terraform destroy: 0 added, 0 changed, 20 destroyed
- Teardown completed: `2026-08-29T22:39:49Z`
- Terraform managed resources after destroy: 0
- Active project instances after destroy: 0
- Project VPCs after destroy: 0
- Project log groups after destroy: 0
- Project alarms after destroy: 0
- Project dashboards after destroy: 0

The IAM bootstrap stack and AWS Budget intentionally remain because they are
non-workload controls used by future portfolio projects.
