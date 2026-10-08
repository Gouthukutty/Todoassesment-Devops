# Project Status

## Completed / Implemented

- [x] Dockerized backend
- [x] Dockerized frontend
- [x] Multi-stage application images
- [x] Health endpoints/checks
- [x] Environment-based configuration
- [x] GitHub Actions CI/CD
- [x] Docker image versioning
- [x] Docker Hub image publishing
- [x] EC2 deployment
- [x] AWS RDS MySQL
- [x] RDS public access disabled
- [x] RDS security-group restriction
- [x] EC2 IAM role
- [x] AWS Secrets Manager
- [x] Deployment-time secret retrieval
- [x] Automatic rollback logic
- [x] Prometheus
- [x] Grafana
- [x] Node Exporter
- [x] cAdvisor included
- [x] Backend-down alert tested

## Requires Final Verification

- [ ] Final architecture diagram matches the deployed environment
- [ ] Final Nginx routing reviewed with `nginx -T`
- [ ] P95 latency metric verified and added to dashboard if available
- [ ] Container restart/uptime metric verified
- [ ] High CPU alert test
- [ ] Controlled rollback test
- [ ] Final security-group review
- [ ] Final CI/CD run after all documentation/configuration changes
- [ ] Final README review
- [ ] Final repository secret scan

## Known Monitoring Limitation

cAdvisor is included, but container-specific metrics must be verified against the EC2 Docker runtime before being presented as a working source of container restart metrics.

## Documentation Structure

```text
aws/
  aws-setup.md
  architecture-diagram.png

docs/
  DEPLOYMENT.md
  MONITORING_AND_OPERATIONS.md
  FAILURE_AND_ROLLBACK.md
  SECURITY.md
  TESTING.md
  TROUBLESHOOTING.md
  PROJECT_STATUS.md
```
