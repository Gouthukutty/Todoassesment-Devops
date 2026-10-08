# Security Controls

## 1. Secrets

The following must never be committed:

- database passwords
- AWS access keys
- SSH private keys
- Cohere/API keys
- Slack webhook URLs
- production `.env` files

Database credentials are stored in AWS Secrets Manager.

## 2. IAM

EC2 uses the IAM role `TodoAssessment-EC2-Role` to retrieve the required database secret.

The deployment does not depend on long-lived AWS access keys stored on EC2.

## 3. RDS

- RDS is not publicly accessible.
- MySQL uses TCP port 3306.
- The RDS security group accepts database traffic from the EC2 security group.
- Public `0.0.0.0/0` access to MySQL is not part of the design.

## 4. Containers

Backend and frontend images use multi-stage builds and non-root runtime users.

Application configuration is externalized through environment variables.

## 5. CI/CD

Docker images are tagged with Git commit SHA values, allowing deployments to be traced to source commits and previous versions to be restored.

GitHub Actions secrets are used for CI/CD credentials such as Docker Hub and EC2 SSH access.

## 6. Network Exposure

Nginx is the intended public application entry point.

Monitoring and administrative interfaces should be restricted to trusted access. Grafana is preferably accessed through an SSH tunnel rather than opening it to the public internet.

The final deployment should be reviewed against the actual EC2 security-group rules and Docker port bindings before submission. Documentation should not claim that a port is private unless the host binding and security group actually enforce that restriction.
