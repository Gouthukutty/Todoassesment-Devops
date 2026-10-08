# DevOps Testing and Validation

## 1. Static Validation

Validated during implementation:

- GitHub Actions YAML structure.
- Docker Compose configuration structure.
- Shell-script syntax.
- Prometheus configuration syntax.
- Prometheus alert-rule syntax.

## 2. Backend and Frontend

Expected local checks:

```bash
cd Backend/todo-summary-assistant
./mvnw -B test
```

```bash
cd Frontend/todo
npm ci
npm run build
```

The sandbox environment used for development did not provide reliable external network access for completing every dependency download, so this document does not claim a full offline Maven/npm build where one was not observed.

## 3. Deployment Health Checks

Backend:

```bash
curl http://127.0.0.1:8081/actuator/health
```

Frontend:

```bash
curl http://127.0.0.1:3000/health
```

Nginx routing was also verified with local HTTP requests to the host-level Nginx endpoint.

## 4. CI/CD

The deployed GitHub Actions workflow performs:

1. Backend test.
2. Frontend build.
3. Docker image build.
4. Docker Hub publish on main-branch deployment.
5. SSH deployment to EC2.
6. Post-deployment health checks.

The deployment stage was successfully exercised against EC2.

## 5. Rollback

A controlled rollback test was completed. The deployment health check was deliberately made to fail, after which `deploy.sh` restored the previous successful image tag and both rollback health checks passed.

## 6. Monitoring

Verified/configured:

- Prometheus backend target.
- Prometheus Node Exporter target.
- Prometheus cAdvisor target.
- Grafana dashboard.
- Backend Down alert, including Firing -> Normal recovery.
- High CPU alert configuration.
- Application request metrics.

Known limitation:

- `http_server_requests_seconds_bucket` is not exposed, so P95 latency is not claimed.
- cAdvisor is scraped but has current-runtime limitations for some per-container metrics.
