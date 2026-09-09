# Deployment, Verification, and Teardown Guide

## Purpose

This guide is the controlled operating procedure for the lab. It separates
validation, planning, deployment, testing, evidence collection, and teardown so
each action has a clear approval point.

## Required Tools

- Terraform version `>= 1.9.0, < 2.0.0`
- AWS CLI version 2
- AWS Systems Manager Session Manager plugin
- A temporary AWS CLI profile that assumes the dedicated portfolio deployment
  role

Do not continue if `aws sts get-caller-identity` reports the account root user.
The root user is reserved for account-level recovery and identity bootstrap.

## 1. Review the Safety Boundary

Read these documents before every deployment:

- [Cost estimate](COST_ESTIMATE.md)
- [Repository cost-safety policy](../../docs/COST_SAFETY.md)
- [Architecture decisions](architecture/DESIGN_DECISIONS.md)

The approved Region is `us-east-2`, and the maximum deployment window is two
hours. Record the start time before applying the plan.

## 2. Select the Non-Root Profile

Before the first deployment, complete the documented
[IAM identity bootstrap](../../identity/README.md). It creates the human sign-in
identity, the MFA-protected deployment role, and the permissions boundary that
Terraform must attach to the EC2 instance role.

Authenticate the human profile with `aws login`. If the Terraform AWS provider
cannot load the resulting `login_session`, configure the documented
`aws-portfolio-admin-sdk` process-credential bridge. The bridge runs
`aws configure export-credentials` and gives the SDK temporary, renewable
credentials without creating long-lived access keys.

In PowerShell, select the dedicated deployment profile and verify its principal:

```powershell
$env:AWS_PROFILE = "aws-portfolio-deployer"
$env:AWS_REGION = "us-east-2"
aws sts get-caller-identity --query Arn --output text
```

The returned ARN must identify an assumed role or approved IAM principal. It
must not end in `:root`.

If AWS CLI commands work but Terraform reports `failed to load assume role`,
verify that `aws-portfolio-deployer` uses `aws-portfolio-admin-sdk` as its
`source_profile` and that the bridge includes `--region us-east-2`. The complete
profile configuration is in the [identity guide](../../identity/README.md).

## 3. Prepare Optional Input

Terraform defaults are sufficient for the lab. To add an email notification,
copy the example file and edit the ignored local copy:

```powershell
Set-Location projects\01-aws-observability-incident-response\terraform
Copy-Item terraform.tfvars.example terraform.tfvars
```

The recipient must confirm the subscription email before SNS can deliver alarm
notifications. Terraform marks the value as sensitive, but the value can still
exist in local Terraform state. Never commit the state or the real `.tfvars`
file.

## 4. Validate Locally

From the project directory, run:

```powershell
.\scripts\terraform-check.ps1
```

This formats nothing and creates nothing in AWS. It checks formatting,
initializes the provider, validates references and types, and runs the mocked
security and cost tests.

## 5. Create and Review a Saved Plan

From the `terraform` directory, run:

```powershell
terraform plan -out=portfolio.tfplan
terraform show -no-color portfolio.tfplan
```

Review every planned action. The expected plan contains one VPC, one subnet, one
internet gateway, one route table, one security group, one EC2 instance, its IAM
role and instance profile, three log groups, one SNS topic, two alarms, and one
dashboard. Stop if Terraform proposes unrelated resources or replacements that
you do not understand.

The saved plan can contain sensitive values. It is ignored by Git and must be
deleted after use.

## 6. Apply the Reviewed Plan

Record the UTC start time, then apply exactly the saved plan:

```powershell
Get-Date -AsUTC
terraform apply portfolio.tfplan
Remove-Item -LiteralPath portfolio.tfplan
```

Using the saved plan prevents an unreviewed configuration change from entering
the deployment between `plan` and `apply`.

## 7. Verify the Workload

Display the Terraform outputs:

```powershell
terraform output
```

Verify the temporary website, replacing the placeholder with the output value:

```powershell
Invoke-WebRequest -Uri "http://PUBLIC_IP" -UseBasicParsing
```

Confirm that Systems Manager recognizes the instance:

```powershell
aws ssm describe-instance-information `
  --filters Key=InstanceIds,Values=INSTANCE_ID `
  --region us-east-2
```

Open a secure session without SSH:

```powershell
aws ssm start-session --target INSTANCE_ID --region us-east-2
```

Inside the instance, verify the services:

```bash
systemctl is-active nginx amazon-ssm-agent amazon-cloudwatch-agent
curl --fail --silent http://localhost/
```

## 8. Verify Observability

In CloudWatch, confirm:

1. The dashboard contains alarm panels, CPU, status checks, memory, network, and
   recent nginx requests.
2. The three log groups contain current streams.
3. The memory metric appears in the `CWAgent` namespace.
4. Both alarms have actions enabled and point to the project SNS topic.
5. The email subscription is `Confirmed` if an email endpoint was configured.

Use the saved [CloudWatch Logs Insights queries](queries/cloudwatch-logs-insights.md)
to inspect application and boot activity.

## 9. Run the Controlled Incident

Follow the [high-CPU incident runbook](runbooks/high-cpu-response.md). Record
times in UTC, capture sanitized evidence, and complete the incident report while
the details are fresh.

## 10. Destroy and Verify

From the `terraform` directory:

```powershell
terraform plan -destroy
terraform destroy
```

After Terraform reports success, verify that no project-tagged resources remain
and check the Billing and Cost Management dashboard. Do not delete the local
state until teardown is confirmed, because Terraform uses that state to identify
what it must remove.

After the zero-resource verification succeeds, delete the generated plan files:

```powershell
Remove-Item -LiteralPath portfolio.tfplan -ErrorAction SilentlyContinue
Remove-Item -LiteralPath teardown.tfplan -ErrorAction SilentlyContinue
```

Both patterns are ignored by Git, but removing used plans also reduces local
exposure because a saved plan can contain resource values.

## When Each Terraform Command Is Used

| Command | When | AWS effect |
| --- | --- | --- |
| `terraform fmt -check` | Before every commit | None |
| `terraform init` | First run or provider change | Downloads providers only |
| `terraform validate` | After configuration changes | None |
| `terraform test` | Before every plan | None because this project uses a mocked provider |
| `terraform plan` | Before every apply or destroy | Reads AWS and previews changes |
| `terraform apply portfolio.tfplan` | After plan approval | Creates the reviewed resources |
| `terraform destroy` | Immediately after evidence collection | Removes managed resources |
