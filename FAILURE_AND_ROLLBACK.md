# Failure and Rollback Strategy

## 1. Faulty Version Is Deployed

The CI/CD pipeline builds Docker images and uses the Git commit ID as the image version.

During deployment:

1. GitHub Actions builds the backend and frontend Docker images.
2. Each Docker image is tagged with the Git commit ID.
3. GitHub Actions connects to the EC2 server.
4. `deploy.sh` gets the database username and password from AWS Secrets Manager.
5. The required Docker images are downloaded.
6. The application containers are started.
7. Backend and frontend health checks are performed.
8. The version is saved as the current working version only after the health checks pass.

If the new version fails the health checks, `deploy.sh` tries to restore the previous working version.

### Rollback Flow

```text
New version deployed
        |
        v
Health checks
        |
     +--+--+
     |     |
   PASS   FAIL
     |     |
     v     v
 Save    Restore
 version previous
          version
             |
             v
        Health checks
             |
        +----+----+
        |         |
      PASS       FAIL
        |         |
        v         v
    Rollback    Critical
    successful   failure
```

---

## 2. Application Crashes After Deployment

If the application crashes after deployment, Docker automatically tries to restart the container.

The Docker Compose configuration uses:

```yaml
restart: unless-stopped
```

The application status can be checked using:

```bash
docker compose ps
```

Backend logs can be checked using:

```bash
docker compose logs --tail=100 backend
```

Frontend logs can be checked using:

```bash
docker compose logs --tail=100 frontend
```

If the crash is caused by the newly deployed version, the previous working version can be restored using the rollback process.

---

## 3. CI/CD Tool Is Unavailable

If GitHub Actions is temporarily unavailable, the application that is already running on EC2 can continue to run.

An authorized operator can manually deploy a specific application version using:

```bash
./deploy.sh VERSION
```

For example:

```bash
./deploy.sh 02294c4eb740e75286a8d69b5efd376821618258
```

Here, `VERSION` means the Git commit ID of the Docker image that should be deployed.

The previous working version can also be deployed again using:

```bash
./deploy.sh "$(cat .current_tag)"
```

GitHub Actions remains the normal method for future deployments.

---

## 4. Secrets Are Leaked

If a password, API key, or other secret is accidentally exposed, the affected secret should be changed immediately.

The recovery steps are:

1. Change the affected secret.
2. Update the secret in AWS Secrets Manager.
3. Check the Git repository for exposed credentials.
4. Remove accidentally committed credentials if any exist.
5. Change affected external credentials if required.
6. Redeploy the application.
7. Verify that the application works with the new secret.

Database credentials are stored in AWS Secrets Manager and are not stored in the Git repository.

The EC2 server accesses AWS Secrets Manager using its IAM role instead of storing AWS access keys on the server.

---

## 5. EC2 Instance Fails

If the EC2 server fails, the application running on that server becomes unavailable.

The recovery process is:

1. Create or restore a replacement EC2 server.
2. Attach the required IAM role.
3. Install Docker and AWS CLI.
4. Configure the required security group.
5. Restore the deployment files.
6. Verify access to AWS Secrets Manager.
7. Deploy the required application version.
8. Check the backend and frontend health.
9. Restore monitoring if required.

The database is hosted separately on Amazon RDS, so the database does not need to be recreated when the EC2 server is replaced.

---

## 6. RDS Database Becomes Unavailable

If the RDS database becomes unavailable, the backend may not be able to read or save application data.

The recovery process is:

1. Check the RDS instance status.
2. Check RDS events.
3. Check connectivity from EC2 to RDS.
4. Check the RDS security group.
5. Check RDS monitoring information.
6. Restore the database from an appropriate backup or snapshot if required.
7. Verify database connectivity.
8. Check the backend health.
9. Verify the application.

For production environments, automated RDS backups should be enabled with an appropriate retention period.

Multi-AZ can also be considered when higher availability is required.

---

# Rollback Principles

The deployment strategy follows these principles:

- Use Git commit IDs as Docker image versions.
- Keep track of the previous working version.
- Perform health checks after deployment.
- Automatically attempt rollback when deployment health checks fail.
- Keep database credentials outside the source code.
- Use an AWS IAM role instead of static AWS credentials.
- Monitor application and infrastructure health.
- Keep production database data on Amazon RDS instead of inside application containers.

---

# Operational Commands

## Check Application Status

```bash
docker compose ps
```

## Check Backend Logs

```bash
docker compose logs --tail=100 backend
```

## Check Frontend Logs

```bash
docker compose logs --tail=100 frontend
```

## Check the Current Working Version

```bash
cat .current_tag
```

## Deploy a Specific Version

Replace `VERSION` with the Git commit ID of the version you want to deploy.

```bash
./deploy.sh VERSION
```

Example:

```bash
./deploy.sh 02294c4eb740e75286a8d69b5efd376821618258
```

## Deploy the Previous Working Version

The previous successful version can be deployed using:

```bash
./deploy.sh "$(cat .current_tag)"
```

## Manual Rollback

A specific previous version can also be restored using:

```bash
./rollback.sh VERSION
```

For example:

```bash
./rollback.sh 02294c4eb740e75286a8d69b5efd376821618258
```

---

# Important Notes

The rollback process is designed to restore the previous Docker image version if a new deployment fails its health checks.

Database credentials are retrieved from AWS Secrets Manager during deployment and are not stored in the Git repository.

The application database is hosted on Amazon RDS separately from the EC2 server.

GitHub Actions is the normal deployment method, while the deployment scripts provide a manual recovery option when required.
