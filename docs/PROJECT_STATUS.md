# Project Status

## Implemented and Verified

- [x] Backend Dockerfile with multi-stage build
- [x] Frontend Dockerfile with multi-stage build
- [x] Non-root runtime configuration
- [x] Environment-based application configuration
- [x] Backend/frontend health endpoints
- [x] GitHub Actions CI/CD
- [x] Docker Hub image publishing
- [x] Git commit SHA image tagging
- [x] EC2 deployment
- [x] RDS MySQL deployment
- [x] RDS public access disabled
- [x] RDS security-group restriction to EC2
- [x] EC2 IAM role for Secrets Manager
- [x] Deployment-time secret retrieval
- [x] Automatic rollback logic
- [x] Controlled automatic rollback test
- [x] Prometheus
- [x] Grafana
- [x] Node Exporter
- [x] cAdvisor included and scraped
- [x] Backend Down alert tested
- [x] High CPU alert configured
- [x] Nginx syntax/routing reviewed

## Known Limitations / Final Review Items

- [ ] P95 latency is not claimed because histogram bucket metrics are not exposed. Average latency can be calculated from request sum/count.
- [ ] cAdvisor has host-runtime limitations for some per-container metrics.
- [ ] Final EC2 security-group screenshots should match the actual current rules.
- [ ] Docker host port bindings should be reviewed and hardened so only intended public services are externally reachable.
- [ ] Final repository secret scan should be completed before submission.
- [ ] Final CI/CD run should be performed after any last repository changes.

## Important Verified Rollback Result

A controlled deployment health-check failure triggered automatic rollback. The previous image version was restored and both backend/frontend rollback health checks passed.

## Current Deployment Tag

The successful deployment tested during the assessment was identified by Git commit SHA. The live `.current_tag` on EC2 should be treated as the authoritative current value.
