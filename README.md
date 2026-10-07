# Todo Summary Assistant — DevOps Assessment

Production-style DevOps enablement for the supplied full-stack Todo Summary Assistant. The original application remains the business application; the additions in this repository provide containerization, CI/CD, AWS deployment, RDS integration, monitoring, health checks, rollback and operational documentation.

## Assessment alignment

The supplied assessment requires a React frontend, Spring Boot backend and MySQL database; Docker containers for frontend/backend; CI/CD; AWS EC2 + private RDS; Prometheus + Grafana; health checks; failure/rollback documentation; and no committed secrets. The repository structure below follows the required locations.

## Architecture

```text
Internet
   |
   v
AWS EC2 Security Group
   | 80/443
   v
Nginx (host)
   |---- / ------------------> React container :3000
   |
   +---- /api/ --------------> Spring Boot container :8081 -> :8080
                                  |
                                  +----> Private RDS MySQL :3306
                                  |
                                  +----> Cohere API / Slack webhook

Prometheus -> Spring Actuator / Node Exporter / cAdvisor
Grafana -> Prometheus
```

See `aws/architecture-diagram.png` for the visual architecture.

## Project structure

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
│   ├── architecture-diagram.png
│   ├── aws-setup.md
│   ├── nginx/todo-summary-assistant.conf
│   └── scripts/setup-ec2.sh
├── monitoring/
│   ├── prometheus.yml
│   ├── alert-rules.yml
│   └── grafana/
├── docker-compose.yml
├── deploy.sh
├── rollback.sh
├── .env.example
├── FAILURE_AND_ROLLBACK.md
└── MONITORING_AND_OPERATIONS.md
```

## What was changed for DevOps enablement

1. Spring Boot configuration now reads database, Cohere, Slack, port and CORS values from environment variables instead of hardcoded credentials.
2. Spring Boot Actuator + Micrometer Prometheus were added to expose health and metrics. This is explicitly allowed by the assessment as DevOps enablement.
3. The frontend API client uses `REACT_APP_API_BASE_URL`; production Docker builds use `/api`, so the browser talks to the same Nginx origin.
4. Backend tests use an H2 test database so CI can run without a real RDS instance.
5. Frontend and backend use multi-stage, non-root Docker images.

No business feature logic was intentionally changed.

## CI/CD

On pull requests to `main`, GitHub Actions runs backend tests and a frontend production build.

On a push to `main`, it additionally:

1. Builds backend and frontend images.
2. Tags each image with the immutable Git commit SHA and `latest`.
3. Pushes both images to Docker Hub.
4. SSHs to EC2.
5. Retrieves runtime secrets from AWS Secrets Manager using the EC2 IAM role.
6. Pulls the exact commit-SHA images.
7. Starts/replaces the Compose services.
8. Runs backend and frontend health checks.
9. Fails the deployment if health checks fail and automatically attempts rollback to the previously recorded successful SHA.

This is intentionally similar to the requested TaskFlow-style GitHub -> Docker Hub -> EC2 flow, but uses immutable SHA tags for safe rollback.

### GitHub secrets

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
EC2_HOST
EC2_USERNAME
EC2_SSH_KEY
```

No database, Cohere, Slack or AWS access key is stored in GitHub.

## Docker Hub repositories

Create:

```text
<dockerhub-user>/todo-summary-backend
<dockerhub-user>/todo-summary-frontend
```

## EC2 setup

1. Launch Ubuntu EC2.
2. Attach an IAM role that can read only the production Secrets Manager secret.
3. Configure the EC2 security group.
4. Run `aws/scripts/setup-ec2.sh`.
5. Copy `docker-compose.yml`, `deploy.sh`, `rollback.sh` and `monitoring/` to `/opt/todo-summary-assistant`.
6. Create `/opt/todo-summary-assistant/.env` with the Docker Hub username and secret ID:

```env
DOCKERHUB_USERNAME=your_dockerhub_username
TODO_SECRET_ID=todo-summary-assistant/prod
```

7. Configure Nginx from `aws/nginx/todo-summary-assistant.conf`.

Detailed AWS/RDS steps are in `aws/aws-setup.md`.

## Local backend

Prerequisites: JDK 17+, Maven wrapper and a MySQL instance. Copy `.env.example` values to your local environment and run:

```bash
cd Backend/todo-summary-assistant
./mvnw spring-boot:run
```

Backend: `http://localhost:8080`
Health: `http://localhost:8080/actuator/health`
Metrics: `http://localhost:8080/actuator/prometheus`

## Local frontend

```bash
cd Frontend/todo
npm ci
REACT_APP_API_BASE_URL=http://localhost:8080/api npm start
```

Frontend: `http://localhost:3000`

## Local production-style containers

For production, use RDS. The included `docker-compose.yml` is designed for EC2 and expects `.env.runtime`. Do not replace RDS with a database container for the production assessment deployment.

## RDS

Use MySQL on Amazon RDS, with public access disabled. Allow TCP 3306 only from the EC2 security group. Store the endpoint and credentials in Secrets Manager. Enable automated backups and document the restore process.

## Monitoring

Prometheus scrapes:
- Spring Boot `/actuator/prometheus`
- Node Exporter
- cAdvisor

Grafana is provisioned with an operations dashboard. Alert rules cover backend availability, high CPU and low disk. See `MONITORING_AND_OPERATIONS.md`.

## Rollback

Every production image is tagged with the Git commit SHA. To roll back:

```bash
cd /opt/todo-summary-assistant
./rollback.sh <known-good-commit-sha>
```

See `FAILURE_AND_ROLLBACK.md` for all six required scenarios.

## Security notes

- No real secrets belong in Git.
- RDS is private.
- EC2 IAM role is used for Secrets Manager access.
- Containers run as non-root users.
- Application ports are bound to localhost.
- Only Nginx is intended to be internet-facing.
- Docker Hub uses a scoped access token stored in GitHub Secrets.

## Reverse proxy

Nginx runs on the EC2 host and is the public entry point. It proxies:

- `/` -> React frontend on `127.0.0.1:3000`
- `/api/` -> Spring Boot backend on `127.0.0.1:8081`

Configure it with `aws/scripts/configure-nginx.sh` after copying the repository to EC2. The application containers are never exposed directly to the Internet.

## Deployment secrets

The EC2 deployment reads runtime secrets from AWS Secrets Manager using the instance IAM role. It creates `.env.runtime` for Spring Boot and `.env.grafana` for Grafana with mode `600`. No database password, API key, webhook, or AWS access key belongs in Git.
