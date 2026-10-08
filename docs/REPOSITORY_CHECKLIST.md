# Final Repository Checklist

## Required Assessment Deliverables

- [x] Backend Dockerfile
- [x] Backend `.dockerignore`
- [x] Frontend Dockerfile
- [x] Frontend `.dockerignore`
- [x] `.github/workflows/ci-cd.yml`
- [x] AWS architecture diagram
- [x] AWS setup documentation
- [x] Prometheus configuration
- [x] Prometheus alert rules
- [x] Grafana dashboard / dashboard evidence
- [x] `docker-compose.yml`
- [x] `.env.example`
- [x] `README.md`
- [x] `FAILURE_AND_ROLLBACK.md`
- [x] `MONITORING_AND_OPERATIONS.md`

## Docker

- [x] Multi-stage backend build
- [x] Multi-stage frontend build
- [x] Non-root runtime
- [x] Health checks
- [x] Environment configuration

## CI/CD

- [x] Push/PR trigger
- [x] Backend test stage
- [x] Frontend build stage
- [x] Docker image build
- [x] SHA image tags
- [x] Docker Hub push
- [x] EC2 deployment
- [x] Post-deployment health checks
- [x] Automatic rollback

## AWS

- [x] EC2
- [x] RDS MySQL
- [x] RDS not publicly accessible
- [x] RDS access restricted to EC2 security group
- [x] EC2 IAM role
- [x] Secrets Manager
- [x] No static AWS credentials required by EC2

## Monitoring

- [x] Prometheus
- [x] Grafana
- [x] Node Exporter
- [x] cAdvisor included
- [x] Request rate
- [x] Error rate
- [x] CPU
- [x] Memory
- [x] Disk
- [x] Backend availability
- [x] Backend Down alert
- [x] High CPU alert
- [x] JVM/application metrics
- [~] Latency: average latency is available; P95 is not available without histogram buckets
- [~] Container-level metrics: cAdvisor is limited by current host runtime

## Final Security Review

- [ ] `.env` is not tracked by Git.
- [ ] No real secrets are present in repository files/history.
- [ ] SSH access is restricted appropriately.
- [ ] Monitoring ports are restricted appropriately.
- [ ] Backend/frontend Docker host ports are not unnecessarily public.
- [ ] RDS 3306 remains restricted to the EC2 security group.

## Final Submission Review

- [ ] Run final `git status --short`.
- [ ] Run a repository secret scan.
- [ ] Run final CI/CD pipeline.
- [ ] Capture final AWS/monitoring screenshots.
- [ ] Confirm the architecture diagram matches the deployed system.
- [ ] Confirm all documentation describes the actual environment.
