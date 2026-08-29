# Portfolio IAM Identity Bootstrap

## Purpose

This folder creates the non-root identity used to deploy and operate the first
portfolio project. The bootstrap is intentionally separate from the Terraform
lab because an identity must exist before Terraform can authenticate safely.

The design has three layers:

1. `aws-portfolio-admin` is the human sign-in identity. It has no access keys
   and no direct workload permissions.
2. `aws-portfolio-deployer` is a temporary, MFA-protected role used by Terraform
   and operational commands.
3. `aws-observability-instance-boundary` limits the EC2 instance role to Systems
   Manager and observability delivery, even if an attached policy changes.

## Why This Design Is Used

The AWS account root user has unrestricted account control and should not run a
workload. A separate human identity provides attribution, MFA supplies a second
authentication factor, and role assumption produces temporary credentials. The
deployment role is scoped to the services and names used by this lab instead of
receiving administrator access.

No password, MFA seed, access key, session token, email address, or account ID
is stored in this repository. CloudFormation also does not create the console
password. The operator enables console access and MFA privately in the AWS
console after the stack is created.

## What Each Resource Does

| Resource | What | How | When it is used |
| --- | --- | --- | --- |
| `HumanUser` | Provides an identifiable non-root human login | Receives only AWS local-development sign-in permission and permission to assume one role | At the beginning of an authenticated work session |
| `DeploymentRole` | Supplies temporary deployment and operations authorization | Trusts only `HumanUser`, requires MFA, lasts at most one hour, and limits regional calls to `us-east-2` | During Terraform plan/apply/destroy and lab verification |
| `InstanceRoleBoundary` | Caps the maximum permissions of the EC2 role | Allows SSM agent traffic, writes to `/portfolio/cloudops/*`, and metrics only in `CWAgent` | Whenever Terraform creates or updates the lab instance role |
| `HumanAssumeRolePolicy` | Connects the human identity to the deployment role | Allows exactly `sts:AssumeRole` on the role created by this stack | When the AWS CLI exchanges the human session for role credentials |

## Permission Boundaries and Policies

An identity policy grants permissions. A permissions boundary does not grant
anything by itself; it defines the maximum permissions that the identity can
receive. The EC2 role therefore needs both its Terraform-managed policies and
this CloudFormation-managed boundary.

The deployment role can pass only the exact project instance role to EC2. It
cannot pass arbitrary roles. It can attach only
`AmazonSSMManagedInstanceCore` to that role, and it can create the role only
when the required boundary is present.

Some AWS read and lifecycle APIs do not support resource-level permissions.
Those statements use `Resource: "*"`, but regional calls are restricted with
`aws:RequestedRegion`, while IAM write permissions use exact role and instance
profile ARNs.

## Bootstrap Workflow

The root user is used once for this identity bootstrap:

1. Validate `bootstrap.yaml` locally with `cfn-lint`.
2. Evaluate the template with the repository's `cfn-guard` rules.
3. Create and inspect a CloudFormation change set. A change set plans changes
   but does not create the IAM resources.
4. Execute the reviewed change set.
5. In the AWS console, privately enable console access for
   `aws-portfolio-admin` and register MFA. Never share the password, QR seed, or
   MFA codes.
6. Authenticate that IAM user with `aws login`.
7. Configure and verify the `aws-portfolio-deployer` role profile.
8. Stop using root for project work.

## Expected Trust Flow

```text
Human operator
  -> aws login as aws-portfolio-admin
  -> MFA-backed sts:AssumeRole
  -> aws-portfolio-deployer temporary session
  -> Terraform creates the observability lab
  -> EC2 receives a bounded instance role
```

## Verification Checklist

- The IAM user has no access keys.
- The IAM user has one AWS-managed sign-in policy and one inline AssumeRole
  policy.
- The deployment role trusts only the IAM user and requires MFA.
- The deployment role session duration is no more than 3,600 seconds.
- The EC2 role cannot be created without the named permissions boundary.
- `iam:PassRole` targets only the project instance role and only the EC2
  service.
- `aws sts get-caller-identity` shows an assumed role before Terraform runs.
- The root user is not used for Terraform plan, apply, verification, or destroy.

## Recovery and Removal

Keep the bootstrap stack while the portfolio project is active. It does not
create billable resources. Remove it only after all Terraform-managed resources
have been destroyed and no workflow depends on the deployment role.

CloudFormation cannot delete an IAM user that still has a manually created
login profile or MFA device. Before intentionally deleting the stack, remove
those two manually managed items from the user. Stack deletion is a destructive
operation and requires a separate explicit decision.
