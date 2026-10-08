# Failure and Rollback Strategy

This document answers the six failure scenarios required by the assessment and describes the recovery mechanisms implemented in the deployment.

## 1. A Faulty Version Is Deployed

Each Docker image is tagged with the Git commit SHA. The last successful deployment tag is stored on EC2 in:

```text
.current_tag
```

`deploy.sh` performs backend and frontend health checks after starting the requested version.

If either health check fails:

1. The failed deployment is reported.
2. Container status and recent logs are printed.
3. The previous successful tag is loaded from `.current_tag`.
4. Backend and frontend images for that tag are pulled.
5. Docker Compose is restarted with the previous tag.
6. Backend and frontend health checks are repeated.
7. `.current_tag` is restored if rollback succeeds.
8. The deployment command exits with failure so CI/CD correctly reports that the requested release failed.

### Rollback Flow

```text
New SHA
  |
  v
Deploy
  |
  v
Health checks
  |
 +----+----+
 |         |
PASS      FAIL
 |         |
 v         v
Save SHA  Restore previous SHA
             |
             v
        Health checks
             |
        +----+----+
        |         |
      PASS       FAIL
        |         |
        v         v
    Recovery    Critical
    complete     incident
```

### Controlled Rollback Test

The automatic rollback mechanism was tested with a controlled health-check failure. The new deployment failed its health check, the script restored the previous successful image tag, and both backend and frontend rollback health checks passed.

## 2. The Application Crashes After Deployment

Docker Compose uses:

```yaml
restart: unless-stopped
```

Therefore Docker attempts to restart a crashed container.

Operational checks:

```bash
docker compose ps
docker compose logs --tail=100 backend
docker compose logs --tail=100 frontend
```

If the crash is caused by the newly deployed image, redeploy the previous known-good SHA:

```bash
./deploy.sh "$(cat .current_tag)"
```

## 3. The CI/CD Tool Is Unavailable

The already-running application can continue serving users independently of GitHub Actions.

For an emergency deployment, an authorized operator with EC2 access can run:

```bash
./deploy.sh <KNOWN_IMAGE_TAG>
```

The normal process remains GitHub Actions because it provides the repeatable build, test, image-publish and deployment workflow.

## 4. Secrets Are Leaked

If a database password, API key, webhook, SSH key or AWS credential is exposed:

1. Revoke or rotate the affected credential immediately.
2. Update the secret in the appropriate secret store.
3. Search Git history and current files for the exposed value.
4. Remove the secret from the repository if it was committed.
5. Rotate related credentials if compromise cannot be ruled out.
6. Redeploy using the new secret.
7. Review access logs and IAM activity where applicable.
8. Confirm the old credential no longer works.

Database credentials are stored in AWS Secrets Manager and are retrieved using the EC2 IAM role.

## 5. The EC2 Instance Fails

If EC2 fails, the application and monitoring containers on that host become unavailable.

Recovery:

1. Provision or restore a replacement EC2 instance.
2. Attach the required IAM role.
3. Apply the required security group.
4. Install Docker, Docker Compose and AWS CLI.
5. Restore the repository/deployment files.
6. Verify access to Secrets Manager.
7. Deploy a known-good image tag.
8. Verify backend and frontend health.
9. Restore Nginx and monitoring access.
10. Confirm RDS connectivity.

Because the database is hosted separately on RDS, an EC2 replacement does not require recreating the database.

## 6. The RDS Database Becomes Unavailable

Impact:

- The backend may fail health checks or database operations.
- Reads/writes to Todo data can fail.
- The frontend may remain reachable but application functionality depending on the database will be degraded or unavailable.

Recovery:

1. Check the RDS instance status.
2. Review RDS events and monitoring.
3. Test network connectivity from EC2.
4. Verify the RDS security group still permits the EC2 security group.
5. Verify the database endpoint and credentials.
6. Restore from an appropriate RDS backup or snapshot when necessary.
7. Re-establish connectivity.
8. Verify backend health.
9. Verify application read/write operations.

For a higher-availability production environment, RDS Multi-AZ and an appropriate automated-backup retention policy should be considered. This assessment deployment should not claim Multi-AZ or backup retention unless those settings are actually enabled and verified.

# Operational Principles

- Deploy immutable SHA-tagged images.
- Keep the last successful version identifiable.
- Perform post-deployment health checks.
- Roll back automatically when deployment health checks fail.
- Keep credentials outside source control.
- Use an IAM role rather than static AWS credentials.
- Keep the database outside the application containers.
- Monitor both application and infrastructure health.
