# Deployment Guide

## 1. Normal CI/CD Deployment

A push to `main` triggers GitHub Actions. The deployment stage connects to EC2 and runs:

```bash
cd /home/ubuntu/todolistassesment
./deploy.sh <IMAGE_TAG>
```

`IMAGE_TAG` is normally the Git commit SHA.

## 2. What `deploy.sh` Does

1. Verifies Docker, AWS CLI, Python 3 and curl are available.
2. Retrieves the RDS credentials from AWS Secrets Manager.
3. Records the previous successful image tag from `.current_tag`.
4. Pulls the requested backend and frontend images.
5. Starts the Docker Compose application.
6. Checks backend `/actuator/health`.
7. Checks frontend `/health`.
8. Saves the new tag only when both health checks pass.
9. If the checks fail, attempts to redeploy the previous successful tag.
10. Exits with failure after a failed deployment so CI/CD does not falsely report success.

## 3. Current Successful Version

Check:

```bash
cat /home/ubuntu/todolistassesment/.current_tag
```

The `.current_tag` file represents the last deployment that passed both application health checks.

## 4. Manual Deployment

```bash
cd /home/ubuntu/todolistassesment
./deploy.sh <KNOWN_IMAGE_TAG>
```

## 5. Manual Rollback

Use a known-good image tag:

```bash
./rollback.sh <KNOWN_GOOD_TAG>
```

or redeploy the tag recorded in `.current_tag`:

```bash
./deploy.sh "$(cat .current_tag)"
```

## 6. Health Checks

Backend:

```bash
curl http://127.0.0.1:8081/actuator/health
```

Frontend:

```bash
curl http://127.0.0.1:3000/health
```

Nginx:

```bash
curl -I http://127.0.0.1/
curl -I http://127.0.0.1/api/
```

A `404` from `/api/` itself is not necessarily a backend failure; it can mean Nginx successfully forwarded the request to the backend but the backend has no route for the exact `/api/` path.

## 7. Important Operational Rule

Do not normally use:

```bash
docker compose up -d
```

for application redeployment because the production database credentials are injected by `deploy.sh`.

If the backend is started without those environment variables, the application can fail with a database authentication error such as `using password: NO`. Recover by running `deploy.sh` with the current known-good image tag.
