# Deployment Guide

## 1. Deployment Architecture

```text
GitHub
  |
  v
GitHub Actions
  |
  +-- Test backend
  +-- Build frontend
  +-- Build Docker images
  +-- Push images to Docker Hub
  |
  v
EC2
  |
  v
deploy.sh
  |
  +-- Read secret from AWS Secrets Manager
  +-- Pull image by Git SHA
  +-- Start Docker Compose
  +-- Check backend health
  +-- Check frontend health
  +-- Roll back if health checks fail
```

## 2. Normal Deployment

From the EC2 application directory:

```bash
cd /home/ubuntu/todolistassesment
./deploy.sh <IMAGE_TAG>
```

`IMAGE_TAG` should normally be the Git commit SHA produced by CI/CD.

## 3. Check Containers

```bash
docker compose ps
```

## 4. Check Logs

```bash
docker compose logs --tail=100 backend
docker compose logs --tail=100 frontend
```

## 5. Check Backend Health

```bash
curl http://127.0.0.1:8081/actuator/health
```

## 6. Check Frontend Health

```bash
curl http://127.0.0.1:3000/health
```

## 7. Check Current Successful Version

```bash
cat /home/ubuntu/todolistassesment/.current_tag
```

## 8. Manual Rollback

```bash
cd /home/ubuntu/todolistassesment
./rollback.sh <PREVIOUS_IMAGE_TAG>
```

The exact rollback command should use an image tag that is known to have previously passed deployment health checks.

## 9. Important Operational Rule

Do not use plain:

```bash
docker compose up -d
```

for normal application redeployment when database credentials are supplied by `deploy.sh`.

Use:

```bash
./deploy.sh <IMAGE_TAG>
```

so the deployment process retrieves the database credentials from AWS Secrets Manager.
