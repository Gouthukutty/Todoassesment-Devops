# Troubleshooting Guide

## Backend Authentication Error: `using password: NO`

### Cause

The backend was started without the environment variables injected by `deploy.sh`.

### Recovery

```bash
cd /home/ubuntu/todolistassesment
./deploy.sh "$(cat .current_tag)"
```

## Backend Health Check Fails

```bash
docker compose ps
docker compose logs --tail=100 backend
curl http://127.0.0.1:8081/actuator/health
```

Then check:

- RDS availability
- RDS endpoint
- security-group connectivity
- Secrets Manager
- IAM role
- database credentials

## Frontend Health Check Fails

```bash
docker compose ps
docker compose logs --tail=100 frontend
curl http://127.0.0.1:3000/health
```

## Nginx Problems

```bash
sudo nginx -t
sudo nginx -T
sudo systemctl status nginx
```

Check for:

- duplicate server blocks
- wrong upstream ports
- syntax errors
- failed reloads

## Grafana Access

Prefer an SSH tunnel rather than exposing Grafana publicly:

```bash
ssh -i YOUR_KEY.pem -L 3001:127.0.0.1:3001 ubuntu@EC2_HOST
```

Then open:

```text
http://localhost:3001
```

## Prometheus Has No Backend Metrics

Check the backend endpoint:

```bash
curl http://127.0.0.1:8081/actuator/prometheus
```

Then verify the Prometheus target and configuration.

## cAdvisor Metrics Are Incomplete

cAdvisor is included and scraped, but the current EC2 Docker environment can report overlayfs layer-identification errors. Do not interpret missing per-container series as proof that Prometheus itself is broken.

Use Spring Boot and Node Exporter metrics for the verified application/host monitoring signals.
