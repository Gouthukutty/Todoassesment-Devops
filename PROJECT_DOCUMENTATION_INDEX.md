# Project Documentation Index

This index is the starting point for reviewing the DevOps assessment submission.

## AWS and Architecture

- `aws/aws-setup.md` — AWS resources, networking, security groups, IAM and Secrets Manager.
- `aws/architecture-diagram.png` — architecture diagram.
- `docs/AWS_ARCHITECTURE.md` — detailed application, CI/CD and AWS architecture.

## Deployment and Operations

- `docs/DEPLOYMENT.md` — normal deployment, health checks and rollback commands.
- `FAILURE_AND_ROLLBACK.md` — required six failure/rollback scenarios.
- `docs/MONITORING_AND_OPERATIONS.md` — monitoring design, metrics, alerts and operational response.
- `MONITORING_AND_OPERATIONS.md` — root-level copy for easy submission review.

## Security and Validation

- `docs/SECURITY.md` — secrets, IAM, RDS and network-security controls.
- `docs/TESTING.md` — validation performed and verification commands.
- `docs/TROUBLESHOOTING.md` — known operational problems and recovery commands.

## Project Control

- `docs/PROJECT_STATUS.md` — implementation status and known limitations.
- `docs/REPOSITORY_CHECKLIST.md` — final submission checklist.

## Monitoring Configuration

- `monitoring/prometheus/prometheus.yml`
- `monitoring/prometheus/alert-rules.yml`
- `monitoring/README.md`

## Documentation Principle

Documentation deliberately distinguishes between:

- implemented and verified behavior,
- configured but not yet tested behavior, and
- known limitations.

This prevents the submission from claiming infrastructure behavior that has not actually been verified.
