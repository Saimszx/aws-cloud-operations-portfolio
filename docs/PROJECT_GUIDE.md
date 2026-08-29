# Project Guide: Why, What, How, and When

This guide explains every tracked part of the portfolio in short, practical
English. It is written for learning, project reviews, and interview preparation.

## How the Project Works as a Whole

1. The repository documents the business problem, safety rules, and design.
2. Terraform describes the AWS resources without creating them immediately.
3. Local checks and GitHub Actions verify CloudFormation, policy-as-code, and Terraform.
4. A non-root deployment role isolates Terraform from the AWS account root user.
5. An approved `terraform plan` will preview the AWS changes.
6. An approved `terraform apply` will create the temporary lab.
7. EC2 user data will install the web server, monitoring agent, and bounded test tool at first boot.
8. CloudWatch will collect signals, show dashboards, and trigger alarms.
9. The runbook will guide incident response and the report will record results.
10. Evidence will be sanitized, committed, and reviewed.
11. `terraform destroy` will remove the temporary AWS environment.

No AWS workload has been deployed yet. The current repository contains the
design, code, safety controls, and validation system.

## Repository-Level Files

### `README.md`

- **Why:** Recruiters need a clear landing page instead of a folder of unexplained code.
- **What:** Introduces Samuel, his certifications, target skills, and project roadmap.
- **How:** Links every project and summarizes its status in a table.
- **When:** Read first; update whenever a project changes status or a new project is added.

### `.gitignore`

- **Why:** Secrets, credentials, Terraform state, and generated files must not enter Git history.
- **What:** A denylist for local-only or sensitive file patterns.
- **How:** Git automatically ignores matching files such as `.tfstate`, `.tfvars`, keys, and `.env` files.
- **When:** Applied whenever Git checks for files to stage or commit.

### `.gitattributes`

- **Why:** Windows and Linux use different line endings, and Linux startup scripts must remain portable.
- **What:** Repository rules for consistent text-file line endings.
- **How:** Keeps shell, Terraform, HCL, YAML, and Markdown files on `LF` while PowerShell uses Windows-friendly `CRLF`.
- **When:** Applied by Git during checkout and when files are added to the index.

### `.github/workflows/terraform-checks.yml`

- **Why:** Every infrastructure change should receive the same repeatable quality checks.
- **What:** A read-only GitHub Actions continuous-integration workflow.
- **How:** Runs `cfn-lint` and CloudFormation Guard for the identity bootstrap, then installs Terraform 1.15.9, checks formatting, initializes providers without a backend, validates the configuration, and runs mocked tests.
- **When:** Runs on relevant pushes, pull requests, or a manual workflow request. It never runs `plan`, `apply`, or `destroy`.

### `docs/PORTFOLIO_ROADMAP.md`

- **Why:** A strong portfolio needs progression and completion criteria.
- **What:** Defines career targets, learning phases, evidence, and quality gates.
- **How:** Converts broad career goals into increasingly advanced projects.
- **When:** Used to choose the next project and decide whether a project is truly complete.

### `docs/COST_SAFETY.md`

- **Why:** AWS resources can create charges even in learning accounts.
- **What:** The repository-wide cost, credential, tagging, and teardown policy.
- **How:** Requires a budget, pre-deployment review, small temporary resources, evidence capture, and deletion checks.
- **When:** Reviewed before, during, and after every AWS deployment.

### `docs/PROJECT_GUIDE.md`

- **Why:** Code is more valuable when the owner can explain it confidently.
- **What:** This plain-English explanation of every project component.
- **How:** Organizes each file by why it exists, what it contains, how it works, and when it is used.
- **When:** Used while studying, reviewing changes, or preparing for interviews.

## Identity Bootstrap

### `identity/bootstrap.yaml`

- **Why:** Terraform must not operate with the AWS account root user.
- **What:** A CloudFormation template for one human IAM user, one deployment role, one AssumeRole policy, and one EC2-role permissions boundary.
- **How:** The user receives only sign-in and AssumeRole permissions; the role requires MFA, expires after one hour, and is scoped to the lab services and resource names.
- **When:** Deployed once with root during account bootstrap and retained while portfolio projects depend on it.

### `identity/README.md`

- **Why:** Identity controls must be understandable and repeatable, not hidden in policy JSON.
- **What:** Documents the trust flow, purpose of every IAM resource, private authentication steps, verification, and recovery.
- **How:** Explains the difference between identity policies and boundaries and records where manual password and MFA work is required.
- **When:** Read before identity deployment, authentication, role use, or intentional stack removal.

### `identity/rules/identity-bootstrap.guard`

- **Why:** Critical identity invariants should fail automatically during code review.
- **What:** CloudFormation Guard rules for resource presence, no CloudFormation-managed password, one-hour sessions, required MFA, and the approved sign-in policy.
- **How:** Guard evaluates the CloudFormation template as policy-as-code and returns a nonzero exit code when a rule fails.
- **When:** Run locally and by GitHub Actions whenever identity files change.

## Project Documentation

### `projects/01-aws-observability-incident-response/README.md`

- **Why:** Each project needs a self-contained technical story.
- **What:** Defines the scenario, objectives, architecture, skills, checklist, safety notes, and results section.
- **How:** Connects the infrastructure code to an operational business problem.
- **When:** Read before deployment and updated as checklist items are verified.

### `projects/01-aws-observability-incident-response/DEPLOYMENT.md`

- **Why:** Cloud changes need an ordered procedure with review and stop points.
- **What:** Defines authentication, validation, planning, deployment, verification, incident testing, and teardown.
- **How:** Uses a non-root AWS profile and a saved Terraform plan so only reviewed changes are applied.
- **When:** Followed from the beginning of every lab run until deletion is confirmed.

### `projects/01-aws-observability-incident-response/COST_ESTIMATE.md`

- **Why:** A temporary lab still needs a measurable financial boundary.
- **What:** Records current pricing inputs, a conservative estimate, a two-hour limit, and a USD 0.60 operational ceiling.
- **How:** Separates hourly infrastructure charges from conservative CloudWatch metric-month assumptions.
- **When:** Rechecked before each deployment because pricing and account benefits can change.

### `architecture/DESIGN_DECISIONS.md`

- **Why:** Architecture choices should include reasoning and tradeoffs, not only diagrams.
- **What:** Explains networking, security, observability, cost choices, and known limitations.
- **How:** Records why the lab uses a public subnet, no SSH, Systems Manager, short log retention, and a small instance.
- **When:** Reviewed before deployment and updated whenever the design changes.

### `runbooks/high-cpu-response.md`

- **Why:** Operations engineers need repeatable response procedures during incidents.
- **What:** A step-by-step high-CPU triage, containment, recovery, and closure procedure.
- **How:** Uses a bounded CPU test, CloudWatch for evidence, and Systems Manager for secure instance access.
- **When:** Followed when the CPU alarm enters the `ALARM` state, especially during the controlled test.

### `queries/cloudwatch-logs-insights.md`

- **Why:** Repeatable queries make log investigation faster and easier to verify.
- **What:** Contains queries for requests, HTTP status codes, popular paths, nginx errors, boot failures, and boot chronology.
- **How:** Parses or filters only the relevant project log group over a narrow time range.
- **When:** Used during deployment verification and incident triage.

### `incident-report/TEMPLATE.md`

- **Why:** An incident must produce a useful record, not only a successful fix.
- **What:** A reusable structure for summary, timeline, detection, root cause, resolution, evidence, and lessons learned.
- **How:** Prompts the operator to record facts and connect monitoring signals to recovery actions.
- **When:** Copied and completed immediately after the controlled incident test.

### `evidence/README.md`

- **Why:** Screenshots and logs can accidentally reveal account or personal information.
- **What:** Rules for acceptable, sanitized portfolio evidence.
- **How:** Lists what may be stored and what must be removed or obscured first.
- **When:** Applied before any screenshot, log excerpt, or deployment output is committed.

## Terraform Configuration

Terraform reads all `.tf` files in the directory as one configuration. File
names organize the code for humans; Terraform builds the dependency order from
resource references.

### `terraform/versions.tf`

- **Why:** Reproducible projects need compatible tool and provider versions.
- **What:** Requires Terraform 1.x and the AWS provider 6.x series.
- **How:** Terraform checks these constraints during initialization.
- **When:** Evaluated during every `terraform init`.

### `terraform/.terraform.lock.hcl`

- **Why:** Two developers should not silently receive different provider builds.
- **What:** Records the selected AWS provider version and official checksums.
- **How:** Terraform creates and verifies it during initialization; unlike state, it belongs in Git.
- **When:** Read by `terraform init` and updated only when provider selections change.

### `terraform/providers.tf`

- **Why:** AWS needs a target Region, consistent tags, and reusable naming.
- **What:** Configures the AWS provider, current-account lookup, project names, and common tags.
- **How:** Variables select the Region while local values generate names and tags for all resources.
- **When:** Used during `plan`, `apply`, refresh, and `destroy`.

### `terraform/variables.tf`

- **Why:** Important settings should be changeable without editing resource code.
- **What:** Defines the Ohio Region, environment, network ranges, instance type, HTTP source, and optional notification email.
- **How:** Types, defaults, descriptions, validation rules, and the `sensitive` flag constrain input.
- **When:** Values are resolved before Terraform creates a plan.

### `terraform/terraform.tfvars.example`

- **Why:** Users need a safe configuration example without committing real personal values.
- **What:** Shows typical lab inputs and an optional commented email setting.
- **How:** A user may copy it to `terraform.tfvars`; the real file is ignored by Git.
- **When:** Prepared before `terraform plan` or `terraform apply` when defaults need changing.

### `terraform/network.tf`

- **Why:** The web workload needs controlled connectivity.
- **What:** Creates the VPC, internet gateway, public subnet, route table, security group, and rules.
- **How:** Port 80 is allowed for the temporary page, outbound traffic supports updates and AWS APIs, and port 22 is never opened.
- **When:** Created during `apply` before EC2 and removed during `destroy` after dependent resources.

### `terraform/iam.tf`

- **Why:** EC2 needs temporary permissions without stored access keys.
- **What:** Creates the instance role, profile, Systems Manager attachment, a restricted CloudWatch policy, and references the bootstrap permissions boundary.
- **How:** The EC2 service assumes the role; permissions allow SSM management, selected log writes, and only the `CWAgent` metric namespace, while the boundary caps the role even if an attached policy changes.
- **When:** Created before the instance starts and used whenever the instance calls AWS services.

### `terraform/logging.tf`

- **Why:** Logs need known destinations, retention, and lifecycle control.
- **What:** Creates Standard-class log groups for nginx access, nginx errors, and cloud-init output.
- **How:** CloudWatch stores each stream for seven days before automatic expiration, while the Standard class keeps every query in the investigation library available.
- **When:** Created before first boot so the agent can publish immediately.

### `terraform/compute.tf`

- **Why:** The lab needs an observable Linux workload.
- **What:** Selects the current Amazon Linux 2023 image and creates one EC2 instance.
- **How:** Attaches networking and IAM, requires IMDSv2, keeps paid detailed monitoring disabled, encrypts an 8-GiB `gp3` disk, deletes the disk with the instance, and passes values to the user-data script.
- **When:** Created after its network, permissions, and log destinations exist.

### `terraform/monitoring.tf`

- **Why:** Operations work requires detection and visibility, not only a running server.
- **What:** Creates an SNS topic, optional email subscription, CPU and status alarms, and a dashboard containing alarm, metric, and log panels.
- **How:** CloudWatch evaluates EC2 and agent metrics; alarms publish both failure and recovery state changes to SNS, and the dashboard uses an eight-hour operational view.
- **When:** Created during `apply`, evaluated continuously while the lab runs, and tested during the incident exercise.

### `terraform/outputs.tf`

- **Why:** Operators need the useful results without searching the console.
- **What:** Exposes the instance ID, temporary URL, SSM command, dashboard name, and SNS topic ARN.
- **How:** Terraform reads attributes from the resources after a successful apply.
- **When:** Displayed after `apply` and available through `terraform output` while state exists.

## Scripts and Execution

### `scripts/user-data.sh`

- **Why:** A new instance should configure itself consistently.
- **What:** Installs nginx and the CloudWatch Agent, creates a test page, enables services, writes the agent configuration, and installs a bounded CPU-test command.
- **How:** EC2 cloud-init runs the script as root; Terraform inserts the Region and log-group names before launch.
- **When:** Runs automatically during the instance's first boot or when Terraform replaces the instance after user-data changes.

The `portfolio-cpu-test` command accepts a duration of 60 through 900 seconds and
one through four workers. It stops automatically, which prevents an abandoned
learning exercise from consuming CPU indefinitely.

### `scripts/terraform-check.ps1`

- **Why:** Windows users need one reliable command for local quality checks.
- **What:** Runs Terraform formatting, provider initialization without a backend, validation, and mocked tests.
- **How:** Stops immediately and reports the exact command if any check returns an error.
- **When:** Run before commits and after changing Terraform files.

### `terraform/tests/security_and_cost.tftest.hcl`

- **Why:** Important controls should fail automatically if a future change weakens them.
- **What:** Tests IMDSv2, disk encryption and deletion, volume size, monitoring mode, the IAM boundary, ingress, log retention, and the high-CPU alarm.
- **How:** Terraform uses a mocked AWS provider during `plan`, so the assertions need no credentials and create no cloud resources.
- **When:** Run locally and by GitHub Actions after every relevant infrastructure change.

## Important Terraform Commands

- `terraform fmt -check -recursive`: checks consistent code formatting; it changes nothing in AWS.
- `terraform init -backend=false -input=false`: downloads or verifies providers for validation; it changes nothing in AWS.
- `terraform validate`: checks that references and configuration are internally valid; it changes nothing in AWS.
- `terraform test`: plans with a mocked provider and evaluates project assertions; it changes nothing in AWS.
- `terraform plan`: previews intended AWS changes; normally it changes nothing in AWS.
- `terraform apply`: creates or modifies the approved AWS resources.
- `terraform destroy`: removes the resources recorded in Terraform state.

`validate` proves that the configuration is structurally valid. It does not prove
that deployment permissions, quotas, pricing, or runtime behavior will succeed.
Those items are verified later through a reviewed plan, controlled deployment,
testing, evidence, and teardown.
