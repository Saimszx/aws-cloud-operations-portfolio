# Project Guide: Why, What, How, and When

This guide explains every tracked part of the portfolio in short, practical
English. It is written for learning, project reviews, and interview preparation.

## How the Project Works as a Whole

1. The repository documents the business problem, safety rules, and design.
2. Terraform describes the AWS resources without creating them immediately.
3. Local checks and GitHub Actions verify the Terraform syntax and formatting.
4. A future approved `terraform plan` will preview the AWS changes.
5. A future approved `terraform apply` will create the temporary lab.
6. EC2 user data will install the web server and monitoring agents at first boot.
7. CloudWatch will collect signals, show dashboards, and trigger alarms.
8. The runbook will guide incident response and the report will record results.
9. Evidence will be sanitized, committed, and reviewed.
10. `terraform destroy` will remove the temporary AWS environment.

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
- **How:** Installs Terraform 1.15.9, checks formatting, initializes providers without a backend, and validates the configuration.
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

## Project Documentation

### `projects/01-aws-observability-incident-response/README.md`

- **Why:** Each project needs a self-contained technical story.
- **What:** Defines the scenario, objectives, architecture, skills, checklist, safety notes, and results section.
- **How:** Connects the infrastructure code to an operational business problem.
- **When:** Read before deployment and updated as checklist items are verified.

### `architecture/DESIGN_DECISIONS.md`

- **Why:** Architecture choices should include reasoning and tradeoffs, not only diagrams.
- **What:** Explains networking, security, observability, cost choices, and known limitations.
- **How:** Records why the lab uses a public subnet, no SSH, Systems Manager, short log retention, and a small instance.
- **When:** Reviewed before deployment and updated whenever the design changes.

### `runbooks/high-cpu-response.md`

- **Why:** Operations engineers need repeatable response procedures during incidents.
- **What:** A step-by-step high-CPU triage, containment, recovery, and closure procedure.
- **How:** Uses CloudWatch for evidence and Systems Manager for secure instance access.
- **When:** Followed when the CPU alarm enters the `ALARM` state, especially during the controlled test.

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
- **What:** Defines Region, environment, network ranges, instance type, HTTP source, and optional notification email.
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
- **What:** Creates the instance role, profile, Systems Manager attachment, and a restricted CloudWatch policy.
- **How:** The EC2 service assumes the role; permissions allow SSM management, selected log writes, and only the `CWAgent` metric namespace.
- **When:** Created before the instance starts and used whenever the instance calls AWS services.

### `terraform/logging.tf`

- **Why:** Logs need known destinations, retention, and lifecycle control.
- **What:** Creates log groups for nginx access, nginx errors, and cloud-init output.
- **How:** CloudWatch stores each stream for seven days before automatic expiration.
- **When:** Created before first boot so the agent can publish immediately.

### `terraform/compute.tf`

- **Why:** The lab needs an observable Linux workload.
- **What:** Selects the current Amazon Linux 2023 image and creates one EC2 instance.
- **How:** Attaches networking and IAM, requires IMDSv2, encrypts an 8-GiB `gp3` disk, and passes values to the user-data script.
- **When:** Created after its network, permissions, and log destinations exist.

### `terraform/monitoring.tf`

- **Why:** Operations work requires detection and visibility, not only a running server.
- **What:** Creates an SNS topic, optional email subscription, CPU and status alarms, and a four-widget dashboard.
- **How:** CloudWatch evaluates EC2 and agent metrics; alarms publish state changes to SNS.
- **When:** Created during `apply`, evaluated continuously while the lab runs, and tested during the incident exercise.

### `terraform/outputs.tf`

- **Why:** Operators need the useful results without searching the console.
- **What:** Exposes the instance ID, temporary URL, SSM command, dashboard name, and SNS topic ARN.
- **How:** Terraform reads attributes from the resources after a successful apply.
- **When:** Displayed after `apply` and available through `terraform output` while state exists.

## Scripts and Execution

### `scripts/user-data.sh`

- **Why:** A new instance should configure itself consistently.
- **What:** Installs nginx and the CloudWatch Agent, creates a test page, enables services, and writes the agent configuration.
- **How:** EC2 cloud-init runs the script as root; Terraform inserts the Region and log-group names before launch.
- **When:** Runs automatically during the instance's first boot or when Terraform replaces the instance after user-data changes.

### `scripts/terraform-check.ps1`

- **Why:** Windows users need one reliable command for local quality checks.
- **What:** Runs Terraform formatting, provider initialization without a backend, and validation.
- **How:** Stops immediately and reports the exact command if any check returns an error.
- **When:** Run before commits and after changing Terraform files.

## Important Terraform Commands

- `terraform fmt -check -recursive`: checks consistent code formatting; it changes nothing in AWS.
- `terraform init -backend=false -input=false`: downloads or verifies providers for validation; it changes nothing in AWS.
- `terraform validate`: checks that references and configuration are internally valid; it changes nothing in AWS.
- `terraform plan`: previews intended AWS changes; normally it changes nothing in AWS.
- `terraform apply`: creates or modifies the approved AWS resources.
- `terraform destroy`: removes the resources recorded in Terraform state.

`validate` proves that the configuration is structurally valid. It does not prove
that deployment permissions, quotas, pricing, or runtime behavior will succeed.
Those items are verified later through a reviewed plan, controlled deployment,
testing, evidence, and teardown.
