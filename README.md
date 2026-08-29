# Samuel Salazar Echeverry - Cloud Operations Portfolio

This repository documents hands-on projects in AWS cloud operations, infrastructure automation, monitoring, security, incident response, and reliability.

## About Me

I am a Computer Information Systems student at Miami Dade College with an interest in cloud operations and cloud engineering. I hold the AWS Certified CloudOps Engineer - Associate and Microsoft Certified: Azure Fundamentals certifications. My goal is to turn foundational knowledge into documented, reproducible, and secure cloud projects.

- Location: Miami, Florida
- Languages: English and Spanish
- GitHub: [@Saimszx](https://github.com/Saimszx)
- Current focus: AWS operations, Linux, Git, infrastructure as code, observability, and troubleshooting

## Certifications

- AWS Certified CloudOps Engineer - Associate
- Microsoft Certified: Azure Fundamentals
- Robotics training in Python, C++, artificial intelligence, IoT, electronics, and 3D design

## Project Portfolio

| Project | Skills demonstrated | Status |
| --- | --- | --- |
| [AWS Observability and Incident Response Lab](projects/01-aws-observability-incident-response/README.md) | EC2, IAM, Systems Manager, CloudWatch, SNS, Linux, Terraform, troubleshooting | In progress |
| Highly Available Static Website | S3, CloudFront, Route 53, ACM, GitHub Actions | Planned |
| Backup and Disaster Recovery Lab | AWS Backup, S3 versioning, lifecycle policies, recovery testing | Planned |
| Serverless Operations and Cost Controls | Lambda, API Gateway, DynamoDB, logging, alarms, budgets | Planned |

## Security Foundation

The [portfolio IAM identity bootstrap](identity/README.md) creates the non-root,
MFA-protected access path used by Terraform. It is defined with CloudFormation,
checked with `cfn-lint`, evaluated with CloudFormation Guard, and intentionally
creates no passwords or long-lived access keys.

## Documentation Standards

Every completed project will include:

- A business or operational scenario
- An architecture diagram
- Infrastructure-as-code files
- Security and cost considerations
- Deployment and teardown instructions
- Test evidence and screenshots
- A troubleshooting or incident runbook
- Lessons learned and possible improvements

## Background Projects

- Moon Camp Challenge - European Space Agency and Airbus Foundation
- Mission to Mars Student Challenge - NASA

These earlier academic projects helped develop teamwork, technical communication, problem solving, and engineering-design skills. The cloud projects in this repository will demonstrate current, job-relevant operational experience.

## Portfolio Roadmap

See the [portfolio roadmap](docs/PORTFOLIO_ROADMAP.md) for the planned progression and completion criteria.

See the [AWS cost safety policy](docs/COST_SAFETY.md) for the guardrails applied to every deployment.

See the [plain-English project guide](docs/PROJECT_GUIDE.md) for a file-by-file explanation of why each component exists, what it does, how it works, and when it runs.

> Security note: This repository will never contain AWS access keys, passwords, private keys, Terraform state files, or other secrets.
