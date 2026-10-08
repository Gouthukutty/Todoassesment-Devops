# Todo Summary Assistant — DevOps Assessment

## 1. Overview

This repository contains the existing Todo Summary Assistant application together with the DevOps enablement required for the assessment.

The application consists of:

- Spring Boot + Maven backend
- React frontend
- MySQL database on Amazon RDS
- Docker containers for backend and frontend
- Docker Compose for the EC2 runtime stack
- GitHub Actions for CI/CD
- Docker Hub for versioned application images
- Amazon EC2 for application hosting
- AWS Secrets Manager for database credentials
- Prometheus and Grafana for monitoring
- Node Exporter for EC2 host metrics
- cAdvisor for optional container metrics
- Nginx as the host-level HTTP reverse proxy

The implementation focuses on DevOps enablement. Business functionality was not intentionally redesigned.

## 2. Assessment Alignment

The assessment requires Docker, CI/CD, AWS EC2 + RDS, externalized secrets, monitoring, rollback/failure documentation, and clear operational documentation. The implementation addresses these areas as follows:

| Requirement | Implementation |
|---|---|
| Backend containerization | Multi-stage Maven/JRE Dockerfile, non-root runtime |
| Frontend containerization | Multi-stage Node/Nginx Dockerfile, non-root runtime |
| Configuration | Environment variables; no production DB credentials in source |
| CI/CD | GitHub Actions on push/PR |
| Image registry | Docker Hub |
| Image versioning | Git commit SHA + `latest` on main deployments |
| EC2 deployment | Automated SSH deployment through `deploy.sh` |
| Health checks | Spring Boot Actuator + frontend `/health` |
| Rollback | Automatic rollback to last successful SHA |
| Database | Amazon RDS MySQL |
| DB security | RDS not publicly accessible; EC2 security group source |
| AWS credentials | EC2 IAM role |
| DB credentials | AWS Secrets Manager |
| Application metrics | Spring Boot Actuator + Micrometer/Prometheus |
| Host metrics | Node Exporter |
| Container metrics | cAdvisor included; current environment has limitations |
| Dashboards/alerts | Grafana dashboard + Backend Down + High CPU alerts |

## 3. Repository Structure

```text
TodoSummaryAssistant/
├── Backend/todo-summary-assistant/
│   ├── src/
│   ├── pom.xml
│   ├── Dockerfile
│   └── .dockerignore
├── Frontend/todo/
│   ├── src/
│   ├── package.json
│   ├── Dockerfile
│   ├── nginx.conf
│   └── .dockerignore
├── .github/workflows/ci-cd.yml
├── aws/
│   ├── aws-setup.md
│   └── architecture-diagram.png
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yml
│   │   └── alert-rules.yml
│   └── README.md
├── docs/
│   ├── AWS_ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   ├── MONITORING_AND_OPERATIONS.md
│   ├── SECURITY.md
│   ├── TESTING.md
│   ├── TROUBLESHOOTING.md
│   ├── PROJECT_STATUS.md
│   └── REPOSITORY_CHECKLIST.md
├── docker-compose.yml
├── deploy.sh
├── rollback.sh
├── .env.example
├── FAILURE_AND_ROLLBACK.md
└── MONITORING_AND_OPERATIONS.md
```

## 4. Local Prerequisites

For local DevOps validation, install:

- Git
- Java 17
- Maven (or use the included Maven wrapper)
- Node.js and npm
- Docker and Docker Compose

The production database is Amazon RDS. Do not run a production database inside Docker.

## 5. Environment Configuration

Use `.env.example` as the template. Create a local `.env` only when required and never commit it.

Important configuration includes:

- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_USERNAME`
- `SPRING_DATASOURCE_PASSWORD`
- `COHERE_API_KEY`
- `SLACK_WEBHOOK_URL`
- `CORS_ALLOWED_ORIGINS`
- `DOCKERHUB_USERNAME`
- `IMAGE_TAG`

Production database credentials are retrieved by `deploy.sh` from AWS Secrets Manager and injected into the deployment environment.

## 6. CI/CD Flow

```text
Git Push / Pull Request
          |
          v
   GitHub Actions
          |
   +------+------+
   |             |
Backend tests  Frontend build
   |             |
   +------+------+
          |
          v
    Docker build
          |
          v
   SHA-tagged images
          |
          v
      Docker Hub
          |
          v
         EC2
          |
       deploy.sh
          |
   Secrets Manager
          |
   Docker Compose
          |
   Health checks
          |
     +----+----+
     |         |
   PASS       FAIL
     |         |
     v         v
 Success    Rollback
```

## 7. Production Deployment

The normal deployment command on EC2 is:

```bash
cd /home/ubuntu/todolistassesment
./deploy.sh <IMAGE_TAG>
```

Use the Git commit SHA as the image tag for deterministic deployments.

Do not normally use `docker compose up -d` directly for application redeployment because database credentials are injected by `deploy.sh`.

## 8. Monitoring

Prometheus scrapes:

- Spring Boot application metrics
- Node Exporter host metrics
- cAdvisor metrics where supported

Grafana currently covers:

- Backend availability
- Request rate
- Error rate
- EC2 CPU
- EC2 memory
- EC2 disk
- JVM heap
- JVM threads
- JVM garbage collection

The available Spring Boot metrics include request duration `sum`, `count`, and `max`. Histogram buckets are not currently exposed, so a true P95 latency query is not claimed. Average latency can be calculated from `sum / count` if a latency panel is required.

## 9. Security Principles

- No production credentials in Git.
- RDS is not publicly accessible.
- RDS MySQL access is restricted to the EC2 security group.
- EC2 uses an IAM role for Secrets Manager access.
- Containers use non-root runtime users where configured.
- Docker images are immutable by commit SHA for deployment traceability.
- Monitoring/admin endpoints should remain restricted to approved access paths.

## 10. Documentation

Start with [`PROJECT_DOCUMENTATION_INDEX.md`](PROJECT_DOCUMENTATION_INDEX.md), then review:

1. `aws/aws-setup.md`
2. `docs/AWS_ARCHITECTURE.md`
3. `docs/DEPLOYMENT.md`
4. `docs/MONITORING_AND_OPERATIONS.md`
5. `FAILURE_AND_ROLLBACK.md`
6. `docs/SECURITY.md`
7. `docs/TESTING.md`
8. `docs/TROUBLESHOOTING.md`
9. `docs/PROJECT_STATUS.md`
10. `docs/REPOSITORY_CHECKLIST.md`

## 11. Important Submission Notes

The assessment asks for reproducibility, security, automation, observability, operational thinking, and documentation. Do not commit:

- `.env` files containing real values
- AWS access keys
- SSH private keys
- database passwords
- API keys
- Slack webhook URLs

The assessment also recommends documenting assumptions where an infrastructure detail is not explicitly specified.
