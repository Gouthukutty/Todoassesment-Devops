# DevOps Testing and Validation

## 1. Source Validation

Verify:

- Dockerfiles exist.
- `.dockerignore` files exist.
- Compose configuration is valid.
- GitHub Actions workflow is valid.
- No credentials are committed.

## 2. Backend

Run:

```bash
mvn -B test
```

Expected result:

```text
BUILD SUCCESS
```

## 3. Frontend

Run:

```bash
npm ci
npm run build
```

Expected result:

```text
Production build succeeds
```

## 4. Docker

Build images:

```bash
docker build -t todoassessment-backend ./backend
docker build -t todoassessment-frontend ./frontend
```

Start the stack:

```bash
docker compose up -d
```

Check:

```bash
docker compose ps
```

## 5. Health Checks

Backend:

```bash
curl http://127.0.0.1:8081/actuator/health
```

Frontend:

```bash
curl http://127.0.0.1:3000/health
```

## 6. CI/CD

Verify that a push to `main`:

1. Runs backend tests.
2. Builds the frontend.
3. Builds Docker images.
4. Pushes images to Docker Hub.
5. Connects to EC2.
6. Runs deployment.
7. Performs health checks.

## 7. Rollback Test

Use a deliberately invalid or known-bad deployment version only in a controlled test.

Verify:

- New deployment fails health checks.
- Previous successful tag is detected.
- Previous version is restored.
- Health checks pass after rollback.

## 8. Monitoring

Verify:

- Prometheus is reachable from the approved administrative path.
- Grafana is running.
- Backend metrics are visible.
- Node Exporter metrics are visible.
- Backend-down alert changes to Firing when backend is stopped.
- Alert returns to Normal after recovery.
