# Failure and Rollback

## 1. Faulty Version Deployed

### Detection

Deployment health checks fail.

### Response

The deployment script:

1. Prints container status.
2. Prints recent backend/frontend logs.
3. Reads the previous successful image tag.
4. Pulls the previous image.
5. Starts the previous version.
6. Runs backend and frontend health checks.
7. Marks rollback successful only when both checks pass.

## 2. Application Container Crashes

Check:

```bash
docker compose ps
docker compose logs --tail=100 backend
```

Check the backend health endpoint:

```bash
curl http://127.0.0.1:8081/actuator/health
```

If required, redeploy the last known-good version:

```bash
./deploy.sh "$(cat .current_tag)"
```

## 3. CI/CD Pipeline Is Unavailable

The application already deployed on EC2 remains available.

Operational response:

1. Do not make unnecessary production changes.
2. Identify whether GitHub Actions, Docker Hub or the deployment connection is unavailable.
3. Restore CI/CD.
4. If an emergency deployment is required, use the approved operational procedure with a known image tag.
5. Record the manual intervention.

## 4. Secrets Are Leaked

If a credential is exposed:

1. Stop using the exposed credential.
2. Rotate the affected credential.
3. Update AWS Secrets Manager.
4. Verify EC2 can retrieve the new secret.
5. Redeploy the application.
6. Remove the secret from source/history where applicable.
7. Review IAM permissions and access logs.

Secrets must never be committed to Git.

## 5. EC2 Failure

If the EC2 instance fails:

1. Check EC2 instance status.
2. Check system and application logs where available.
3. Restore the EC2 host or replace the instance.
4. Install the required runtime components.
5. Restore the application deployment files.
6. Attach the required IAM role.
7. Run the deployment procedure.
8. Verify RDS connectivity.
9. Verify Nginx, frontend and backend health.

Application data remains in RDS rather than on the EC2 instance.

## 6. RDS Unavailable

Symptoms may include:

- Backend database connection errors.
- Application requests failing.
- Spring Boot database connection failures.

Response:

1. Check RDS status in AWS.
2. Verify RDS security-group rules.
3. Verify the EC2-to-RDS network path.
4. Verify the database endpoint and port.
5. Verify credentials from Secrets Manager.
6. Check database health and capacity.
7. Do not recreate the database without confirming data-loss implications.

## Rollback Principles

- Prefer immutable image tags based on Git SHA.
- Keep the previous successful image available.
- Validate application health after deployment.
- Roll back only to a known-good version.
- Do not modify application business logic as part of rollback.
