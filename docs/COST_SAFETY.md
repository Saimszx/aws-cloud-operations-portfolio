# AWS Cost Safety Policy

This portfolio uses temporary learning environments. Cost controls are part of every project, not an afterthought.

## Account Guardrails

- Keep the AWS Free account plan while the required services remain available.
- Create a zero-spend AWS Budget that alerts when actual spending exceeds USD 0.01.
- Review the Billing and Cost Management dashboard before and after every deployment.
- Do not create or join AWS Organizations and do not enable AWS Control Tower while introductory credits are active.
- Never assume that a service is free; verify current pricing and credit eligibility before deployment.

## Deployment Rules

- Prepare and validate infrastructure code before creating cloud resources.
- Estimate the expected cost and define a maximum deployment window.
- Tag resources with project, environment, owner, and managed-by values.
- Prefer small, temporary, Free Tier-eligible resources when they meet the learning objective.
- Avoid high-cost default architecture components such as NAT gateways unless the project explicitly requires and budgets for them.
- Capture evidence promptly, then destroy temporary resources.
- Verify deletion in both the infrastructure tool output and the AWS console.

## Secret Safety

- Do not use the AWS account root user for project deployment.
- Do not create or commit long-lived AWS access keys.
- Prefer temporary, role-based credentials and AWS CloudShell for initial administration.
- Never commit passwords, private keys, `.env` files, Terraform state, or credential files.

## Project Cost Checklist

- [ ] Pricing and Free Tier eligibility reviewed
- [ ] Budget notification active
- [ ] Estimated maximum cost documented
- [ ] Deployment start time recorded
- [ ] Resource tags applied
- [ ] Evidence captured
- [ ] Infrastructure destroyed
- [ ] Billing dashboard checked after teardown

## Official References

- [AWS Free Tier documentation](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier.html)
- [AWS Free Tier FAQs](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier-FAQ.html)
- [AWS Free Tier credit activities](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier-plans-activities.html)
- [AWS CloudShell documentation](https://docs.aws.amazon.com/cloudshell/latest/userguide/welcome.html)
