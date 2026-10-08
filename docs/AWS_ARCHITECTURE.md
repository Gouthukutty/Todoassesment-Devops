# AWS Architecture

## 1. Overview

The Todo Summary Assistant is deployed on AWS using a small, production-style architecture.

The main components are:

- **Amazon EC2** – hosts the application and monitoring containers.
- **Docker** – containerizes the frontend, backend, and monitoring services.
- **Nginx** – runs directly on the EC2 host as the public web server and reverse proxy.
- **Amazon RDS for MySQL** – stores persistent application data.
- **AWS Secrets Manager** – securely stores database credentials.
- **IAM Role** – allows EC2 to read the required database secret.
- **Security Groups** – control network access.
- **GitHub Actions** – automates build, test, image publishing, and deployment.
- **Docker Hub** – stores the backend and frontend images.
- **Prometheus** – collects metrics.
- **Grafana** – provides dashboards and alerts.
- **Node Exporter** – collects EC2 host metrics.
- **cAdvisor** – included for container metrics.

---

## 2. High-Level Architecture

```text
                         Internet Users
                               |
                               v
                      Public IP / Domain
                               |
                               v
                 +--------------------------+
                 |     Nginx on EC2 Host    |
                 |       :80 / :443         |
                 |      Reverse Proxy       |
                 +------------+-------------+
                              |
                    +---------+---------+
                    |                   |
                    v                   v
           +----------------+  +----------------+
           | Frontend       |  | Backend        |
           | Docker         |  | Docker         |
           |                |  |                |
           | React          |  | Spring Boot    |
           | application    |  | REST API       |
           +--------+-------+  +-------+--------+
                                      |
                                      | MySQL :3306
                                      | EC2 SG only
                                      v
                              +--------------------+
                              |   Amazon RDS       |
                              |      MySQL         |
                              |                    |
                              | Not publicly       |
                              | accessible         |
                              +--------------------+

        EC2 IAM Role
             |
             v
      AWS Secrets Manager
             |
             v
      Database Credentials


      GitHub
         |
         v
   GitHub Actions
         |
         v
     Docker Hub
         |
         v
        EC2
```

---

# 3. Application Architecture

The application has two main application containers.

### Frontend

The frontend is a React application built as a production Docker image. The public entry point is the **host-level Nginx server on EC2**, which reverse-proxies requests to the Dockerized frontend.

```text
React source
     |
     v
Node.js build
     |
     v
Production static files
     |
     v
Nginx
     |
     v
Browser
```

Nginx is **not** part of the frontend Docker container in the deployed AWS architecture. Nginx runs directly on the EC2 host and acts as the public reverse proxy. The frontend container provides the React application and its health endpoint:

```text
/health
```

### Backend

The backend is a Spring Boot application.

```text
Frontend
    |
    v
Spring Boot REST API
    |
    v
RDS MySQL
```

The backend exposes:

```text
/actuator/health
/actuator/prometheus
```

for health checking and monitoring.

---

# 4. Nginx

Nginx is used as the production web server for the React frontend.

The frontend Dockerfile uses:

```text
Node.js
    |
    | Build
    v
Nginx
```

The final frontend container runs Nginx rather than the development React server.

Nginx:

- Serves the React static files.
- Supports the React single-page application routing.
- Provides the `/health` endpoint.
- Runs as part of the frontend Docker container.
- Uses a non-root runtime configuration.

The frontend container maps:

```text
EC2 port 3000
        |
        v
Frontend container port 8080
        |
        v
Nginx
```

The current architecture does **not** require a separate Nginx installation on the EC2 host because Nginx is included in the frontend container.

---

# 5. Amazon EC2

Amazon EC2 is the main application server.

Docker runs the following services:

| Container | Purpose |
|---|---|
| Frontend | React application running in Docker |
| Backend | Spring Boot REST API |
| Prometheus | Metrics collection |
| Grafana | Monitoring dashboards and alerts |
| Node Exporter | EC2 host metrics |
| cAdvisor | Container metrics |

The application deployment files are stored on the EC2 server under:

```text
/home/ubuntu/todolistassesment/
```

Important deployment files include:

```text
docker-compose.yml
deploy.sh
rollback.sh
.env
.current_tag
```

---

# 6. Amazon RDS MySQL

Amazon RDS for MySQL is used as the production database.

The database is separate from the EC2 application server.

Application data is therefore stored outside the application containers.

The connection is:

```text
EC2
 |
 | TCP 3306
 v
RDS MySQL
```

The RDS instance is **not publicly accessible**.

The database is not exposed directly to the internet.

---

# 7. RDS Security

The RDS security group allows MySQL traffic only from the EC2 security group.

The important rule is:

```text
Protocol: TCP
Port: 3306
Source: EC2 Security Group
```

Therefore:

```text
Public Internet
      |
      X
      |
   RDS MySQL
```

Direct public access to MySQL is not allowed.

The intended connection is:

```text
EC2
 |
 | 3306
 v
RDS MySQL
```

There is no public `0.0.0.0/0` rule for RDS port `3306`.

---

# 8. EC2 Security Group

The EC2 security group controls access to the EC2 instance.

Only the required application, administration, and configured monitoring access is allowed.

The security model is:

```text
Internet
   |
   v
EC2 Security Group
   |
   +--> Required application access
   |
   +--> Administrative access
   |
   +--> Required monitoring access
```

RDS port `3306` is not opened publicly.

RDS accepts MySQL traffic from the EC2 security group.

---

# 9. IAM Role

The EC2 instance uses the IAM role:

```text
TodoAssessment-EC2-Role
```

The role allows the EC2 instance to retrieve the database secret from AWS Secrets Manager.

The EC2 server does not use permanent AWS access keys stored on the server.

The access flow is:

```text
EC2
 |
 | IAM Role
 v
AWS Secrets Manager
 |
 v
Database credentials
```

---

# 10. IAM Permission

The EC2 role follows the principle of least privilege.

The required permission is:

```text
secretsmanager:GetSecretValue
```

The permission is restricted to the required database secret.

The EC2 instance therefore does not need broad AWS permissions for this application.

---

# 11. AWS Secrets Manager

Database credentials are stored in AWS Secrets Manager.

The secret is:

```text
todoassessment/rds
```

It contains:

```text
username
password
```

The database credentials are not stored in the Git repository.

They are also not hardcoded in the application source code.

---

# 12. How Database Credentials Reach the Backend

During deployment, `deploy.sh` retrieves the database credentials from AWS Secrets Manager.

The complete flow is:

```text
GitHub Actions
      |
      v
     EC2
      |
      | IAM Role
      v
Secrets Manager
      |
      | username + password
      v
deploy.sh
      |
      | environment variables
      v
Spring Boot Backend
      |
      | MySQL : 3306
      v
RDS MySQL
```

This keeps database credentials outside the source code.

---

# 13. Docker Architecture

The application uses Docker for containerization.

The backend and frontend use production-oriented Dockerfiles with:

- Multi-stage builds
- Smaller runtime images
- Non-root runtime users
- Environment-based configuration
- Health checks

The frontend uses:

```text
Node.js
  |
  | Build React application
  v
Nginx runtime image
```

The backend uses:

```text
Maven
  |
  | Build Spring Boot application
  v
Java runtime image
```

Docker Compose runs the application and monitoring services on EC2.

---

# 14. Docker Compose Services

The production Compose stack contains:

```text
backend
frontend
prometheus
node-exporter
cadvisor
grafana
```

The database is **not** included in Docker Compose for production.

The production database runs on Amazon RDS.

---

# 15. CI/CD Pipeline

GitHub Actions is used for CI/CD.

The pipeline is triggered by:

- Push to the repository
- Pull request to the main branch

The pipeline performs:

```text
Git Push
   |
   v
GitHub Actions
   |
   +--> Backend tests
   |
   +--> Frontend build
   |
   +--> Docker image build
   |
   +--> Tag images with Git commit SHA
   |
   +--> Push images to Docker Hub
   |
   +--> Connect to EC2
   |
   +--> Run deploy.sh
   |
   +--> Health checks
   |
   v
Deployment Complete
```

The deployment is automated and repeatable.

---

# 16. Docker Hub

Docker Hub stores the application images.

The project uses separate images for:

```text
Backend
gouthukutty/todoassessment-backend

Frontend
gouthukutty/todoassessment-frontend
```

Images are tagged using the Git commit SHA.

For example:

```text
gouthukutty/todoassessment-backend:<commit-sha>
gouthukutty/todoassessment-frontend:<commit-sha>
```

Commit-based tags make each deployment identifiable and allow previous versions to be restored.

---

# 17. Deployment on EC2

GitHub Actions connects to EC2 and runs:

```bash
./deploy.sh <version>
```

The deployment script:

1. Checks required tools.
2. Retrieves database credentials from Secrets Manager.
3. Pulls the required backend image.
4. Pulls the required frontend image.
5. Starts the application using Docker Compose.
6. Checks the backend health endpoint.
7. Checks the frontend health endpoint.
8. Saves the version only after successful health checks.
9. Automatically attempts rollback if deployment health checks fail.

---

# 18. Health Checks

The backend health endpoint is:

```text
/actuator/health
```

The frontend health endpoint is:

```text
/health
```

The Docker containers also have health checks configured.

The deployment script performs additional health checks after starting the new version.

The deployment is successful only when both backend and frontend health checks pass.

---

# 19. Rollback

Docker images are tagged using the Git commit SHA.

The last successful version is stored on EC2 in:

```text
.current_tag
```

If a new deployment fails its health checks:

```text
New Version
    |
    v
Health Check
    |
 +--+--+
 |     |
PASS  FAIL
 |     |
 v     v
Keep   Restore
new    previous
version version
```

The previous working version can also be deployed manually using:

```bash
./deploy.sh "$(cat .current_tag)"
```

This allows recovery without changing the application business logic.

---

# 20. Monitoring Architecture

Prometheus and Grafana run on the EC2 instance.

Application monitoring:

```text
Spring Boot
     |
     | Actuator / Prometheus metrics
     v
Prometheus
     |
     v
Grafana
```

EC2 host monitoring:

```text
EC2
 |
 v
Node Exporter
 |
 v
Prometheus
 |
 v
Grafana
```

Container monitoring:

```text
Docker
 |
 v
cAdvisor
 |
 v
Prometheus
```

cAdvisor is included as required/optional container monitoring support. On the current EC2 environment, container-specific cAdvisor metrics are limited by the host Docker storage and cgroup configuration, so the main dashboard relies on Spring Boot and Node Exporter metrics.

---

# 21. Monitoring Metrics

The Grafana dashboard monitors:

- Backend availability
- Backend request rate
- Backend error rate
- EC2 CPU usage
- EC2 memory usage
- EC2 disk usage
- JVM heap usage
- JVM threads
- JVM garbage collection activity

Alerts include:

- Backend down
- High EC2 CPU usage

---

# 22. Security Controls

The deployment uses the following security controls:

- RDS is not publicly accessible.
- RDS port `3306` accepts traffic only from the EC2 security group.
- Database credentials are stored in AWS Secrets Manager.
- EC2 uses an IAM role instead of static AWS access keys.
- Secrets are not committed to Git.
- Docker containers run as non-root users.
- Application configuration is supplied through environment variables.
- Monitoring and administrative services are not unnecessarily exposed publicly.
- Production database data is stored in RDS rather than inside a Docker container.

---

# 23. Network and Data Flow

### User to Application

```text
User
 |
 v
EC2
 |
 v
Nginx
 |
 v
React Frontend
 |
 v
Spring Boot Backend
```

### Application to Database

```text
Spring Boot Backend
        |
        | MySQL : 3306
        v
Amazon RDS MySQL
```

### EC2 to Secrets Manager

```text
EC2
 |
 | IAM Role
 v
AWS Secrets Manager
 |
 v
Database Credentials
```

### CI/CD to EC2

```text
GitHub
 |
 v
GitHub Actions
 |
 v
Docker Hub
 |
 v
EC2
 |
 v
Docker Compose
```

---

# 24. AWS Components Summary

| Component | Purpose |
|---|---|
| Amazon EC2 | Hosts the application and monitoring containers |
| Docker | Containerizes application services |
| Nginx | Public web server and reverse proxy on the EC2 host |
| Amazon RDS MySQL | Stores persistent application data |
| AWS Secrets Manager | Securely stores database credentials |
| IAM Role | Allows EC2 to retrieve the required secret |
| Security Groups | Control network access |
| GitHub Actions | Automates CI/CD |
| Docker Hub | Stores Docker images |
| Prometheus | Collects metrics |
| Grafana | Dashboards and alerting |
| Node Exporter | Collects EC2 host metrics |
| cAdvisor | Provides container metrics |

---

# 25. Final Architecture Summary

The final deployment separates public web traffic, application services, database storage, credentials, deployment, and monitoring.

```text
                              INTERNET
                                  |
                                  v
                         PUBLIC IP / DOMAIN
                                  |
                                  v
                    +-------------------------+
                    |     NGINX ON EC2        |
                    |       :80 / :443        |
                    |      Reverse Proxy      |
                    +-----------+-------------+
                                |
                 +--------------+--------------+
                 |                             |
                 v                             v
       +--------------------+        +--------------------+
       | Frontend Docker    |        | Backend Docker     |
       |                    |        |                    |
       | React Application  |        | Spring Boot        |
       |                    |        | REST API           |
       +--------------------+        +---------+----------+
                                               |
                                               | TCP 3306
                                               v
                                      +--------------------+
                                      |    Amazon RDS      |
                                      |      MySQL          |
                                      |                    |
                                      | Not Publicly       |
                                      | Accessible         |
                                      +--------------------+

                         EC2 IAM ROLE
                              |
                              v
                    AWS SECRETS MANAGER
                              |
                              v
                       DB Credentials


       GitHub
          |
          v
   GitHub Actions
          |
          v
      Docker Hub
          |
          v
         EC2
          |
          v
    Docker Compose


    Spring Boot ─────────────┐
                             |
    EC2 → Node Exporter ─────┤
                             v
    Docker → cAdvisor ───> Prometheus
                             |
                             v
                          Grafana
```

## Key Design Decisions

1. **EC2** is used for application hosting as required by the assessment.
2. **Nginx runs directly on the EC2 host** as the public web server and reverse proxy.
3. **The React frontend runs in Docker** behind the host-level Nginx.
4. **Spring Boot runs in Docker** behind the host-level Nginx.
5. **RDS MySQL** is used for persistent production data.
6. **RDS is not publicly accessible.**
7. **RDS port 3306 is restricted to the EC2 security group.**
8. **AWS Secrets Manager stores database credentials.**
9. **An EC2 IAM role provides secure access to Secrets Manager.**
10. **GitHub Actions provides automated CI/CD.**
11. **Docker Hub stores versioned application images.**
12. **Git commit SHA tags provide traceable deployments and rollback support.**
13. **Prometheus and Grafana provide monitoring and alerting.**
14. **Node Exporter provides EC2 infrastructure metrics.**
15. **cAdvisor is included for container monitoring, with its current EC2 limitations documented.**
16. **Docker Compose runs the application and monitoring services on EC2.**
17. **Health checks are performed after deployment.**
18. **The deployment script supports automatic rollback when health checks fail.**
19. **No application business logic is changed for the AWS deployment; the changes are focused on DevOps enablement.**
