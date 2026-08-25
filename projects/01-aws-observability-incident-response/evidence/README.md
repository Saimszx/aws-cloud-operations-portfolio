# Evidence Guidelines

Store only sanitized project evidence in this directory.

Acceptable evidence includes:

- Architecture diagrams
- CloudWatch charts with account identifiers removed
- Alarm state transitions
- Sanitized log excerpts
- Terraform plan and apply summaries without credentials or sensitive values
- Teardown confirmation

Before committing an image, remove or obscure:

- AWS account IDs
- Email addresses
- Access keys, tokens, and session details
- Billing or payment information
- Unnecessary public IP addresses
- Browser tabs and unrelated personal information

Raw AWS console screenshots should remain outside the Git repository until they have been reviewed and sanitized.
