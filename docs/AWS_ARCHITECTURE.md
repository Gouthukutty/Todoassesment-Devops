# AWS and Application Architecture

## 1. End-to-End Architecture

```text
                         +------------------+
                         |      GitHub      |
                         +--------+---------+
                                  |
                                  v
                         +------------------+
                         | GitHub Actions    |
                         | Test / Build /    |
                         | Publish / Deploy  |
                         +--------+---------+
                                  |
                                  v
                         +------------------+
                         |    Docker Hub     |
                         | SHA-tagged images |
                         +--------+---------+
                                  |
                                  v
+----------------------------------------------------------------+
|                           AWS EC2                              |
|                                                                |
|  Host Nginx :80                                                |
|       |                                                        |
|       +---- / ------> React frontend container                 |
|       |                   :3000                                |
|       |                                                        |
|       +---- /api/ ---> Spring Boot backend container            |
|                           :8081                                |
|                              |                                 |
|                              | MySQL :3306                     |
|                              v                                 |
|                       +-------------+                          |
|                       | RDS MySQL   |                          |
|                       | Private     |                          |
|                       +-------------+                          |
|                                                                |
|  Prometheus -> Grafana                                        |
|       ^                                                        |
|       +-- Spring Boot Actuator                                 |
|       +-- Node Exporter                                       |
|       +-- cAdvisor (limited on current runtime)                |
+----------------------------------------------------------------+
                                  ^
                                  |
                         IAM Role / Secrets
                                  |
                         +------------------+
                         | Secrets Manager  |
                         +------------------+
```

## 2. CI/CD

GitHub Actions is triggered by pushes and pull requests to `main`.

The pipeline:

1. Checks out the repository.
2. Runs backend tests.
3. Builds the frontend.
4. Builds backend and frontend Docker images.
5. Tags deployable images with the Git commit SHA.
6. Pushes images to Docker Hub for main-branch deployments.
7. Connects to EC2 over SSH.
8. Runs `deploy.sh <IMAGE_TAG>`.
9. The deployment script retrieves DB credentials and starts the selected images.
10. Backend and frontend health checks determine deployment success.
11. Failed health checks trigger rollback to the previous successful tag.

## 3. Security Boundaries

The important security boundary is the RDS database. RDS is not publicly accessible and MySQL access is restricted to the EC2 security group.

AWS credentials are not stored on the host. The EC2 IAM role is used to retrieve the Secrets Manager secret.

## 4. Docker Design

### Backend

- Multi-stage Maven build.
- Runtime image contains only the required Java runtime and application artifact.
- Non-root runtime user.
- Actuator health endpoint.

### Frontend

- Multi-stage Node build.
- Nginx runtime image.
- Non-root runtime configuration.
- `/health` endpoint for deployment checks.

## 5. Monitoring

Spring Boot exposes Prometheus-compatible metrics through Actuator/Micrometer.

Node Exporter supplies EC2 host metrics.

cAdvisor is deployed and scraped, but the current EC2 Docker environment has limitations for some per-container metrics. The monitoring documentation therefore avoids claiming complete container-level coverage.
