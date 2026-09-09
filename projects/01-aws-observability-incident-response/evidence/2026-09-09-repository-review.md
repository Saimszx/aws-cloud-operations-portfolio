# Repository Review - September 9, 2026

## Scope and Results

This review checked the current local repository without deploying a new AWS
workload. Historical runtime results remain in the
[August 29 validation summary](2026-08-29-validation-summary.md).

| Check | Observed result |
| --- | --- |
| Terraform formatting | Passed |
| Terraform validation | Passed |
| Mocked Terraform tests | Two runs passed, including the optional email input |
| CloudFormation lint | 0 errors, 0 warnings, 0 informational findings |
| CloudFormation Guard | Seven rules passed |
| Cleanup-verifier offline tests | Six scenarios passed; no AWS calls |
| Local Terraform state | No managed resources and no outputs |
| Public documentation | Updated to distinguish historical outcomes from pending work |

The additional email test checks subscription resource creation in a mocked
plan. It does not send email or prove AWS delivery. Mocked IAM policy-document
data also means these Terraform tests do not validate effective AWS permissions.
CloudFormation Guard checks selected structural invariants, not complete IAM
policy evaluation.

## IAM Update and Pending Role Verification

The deployment profile initially returned a session-expired error. After a
temporary bootstrap login, the existing identity stack was inspected and an
UPDATE change set was created using all previous parameter values.

- Change set: `portfolio-alarm-history-read-20260909`
- Template comparison before execution: the only added line was `cloudwatch:DescribeAlarmHistory`
- Direct change: deployment-role inline policy, no replacement
- Indirect change: reevaluation of the human AssumeRole policy reference, no replacement
- Pre-deployment validation errors: none returned by `describe-events`
- Stack outcome: `UPDATE_COMPLETE`
- Post-update comparison: deployed template exactly matched the repository
- Temporary bootstrap login: logged out after verification

The subsequent human-profile login selected root in the browser. The CLI
offered to overwrite the existing IAM profile; that overwrite was declined.
The profile was preserved. A successful authenticated read through the
deployment role and a fresh service-level resource inventory remain pending
renewal of the human IAM session. No new workload was deployed during this review.

## Release Boundary

The operator explicitly deferred local IAM login troubleshooting and fresh
account checks until a later session. The portfolio release therefore includes
the completed historical exercise, validated infrastructure code, operating
procedures, and a repeatable read-only verifier. It does not claim a new live
deployment, a successful renewed IAM session, or a fresh empty AWS inventory.

The cleanup verifier rejects the wrong principal before inventory reads, checks
the alarm-history response, and fails on API errors or remaining resources. Its
six offline scenarios cover clean responses, wrong identity, denied reads,
missing history fields, invalid resource counts, and nonzero resource counts.
They prove local control flow, not current AWS authorization.

The historical run observed alarm transitions and configured SNS action targets.
Successful SNS publication and recipient delivery are not independently proven
by the retained evidence. The incident report and project overview now state
that limitation explicitly.
