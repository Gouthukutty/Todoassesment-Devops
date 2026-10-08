# Security

## Secrets

Database credentials are stored in AWS Secrets Manager.

Do not commit:

- Database passwords
- AWS access keys
- SSH private keys
- API keys
- Slack webhook URLs
- `.env` files containing secrets

## IAM

EC2 uses an IAM role instead of static AWS access keys.

The role should have only the permissions required by the deployment.

## RDS

- Public accessibility is disabled.
- MySQL port 3306 is restricted to the EC2 security group.
- No public `0.0.0.0/0` database access.

## Docker

Application images use production-oriented multi-stage builds and non-root runtime users where configured.

## Network Exposure

The intended public application entry point is Nginx over HTTP/HTTPS.

Administrative and monitoring services should be restricted and should not be unnecessarily exposed to the public internet.

## CI/CD

Docker images are tagged using Git commit SHA so that deployments are traceable and rollback targets are deterministic.
