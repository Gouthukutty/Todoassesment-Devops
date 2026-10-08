# AWS Setup

## 1. AWS Architecture

The production-style deployment uses:

- Amazon EC2 for application and monitoring containers.
- Amazon RDS for MySQL persistence.
- AWS Secrets Manager for database credentials.
- An EC2 IAM role for access to Secrets Manager.
- Security groups to restrict database access.
- Nginx on the EC2 host as the public HTTP reverse proxy.

See `architecture-diagram.png` and `docs/AWS_ARCHITECTURE.md` for the complete flow.

## 2. Region and Resources

The deployed environment uses AWS region:

```text
ap-south-2
```

The application EC2 instance and RDS database are in the same VPC so the application can reach the private database over the VPC network.

The RDS endpoint is used by the backend through the environment variable `SPRING_DATASOURCE_URL`.

## 3. RDS MySQL

The production database is Amazon RDS for MySQL.

The database is intentionally not publicly accessible. The assessment specifically requires RDS to accept connections only from the EC2 security group and not be exposed publicly.

Database traffic:

```text
EC2 security group
      |
      | TCP 3306
      v
RDS MySQL
```

The RDS security group permits MySQL traffic from the EC2 security group rather than from `0.0.0.0/0`.

## 4. Database Credentials

Database credentials are stored in AWS Secrets Manager.

The EC2 instance retrieves the secret using its IAM role. `deploy.sh` extracts the username and password and exports them for the Docker Compose deployment.

Flow:

```text
EC2 IAM Role
     |
     v
Secrets Manager
     |
     v
 deploy.sh
     |
     v
Docker Compose environment
     |
     v
Spring Boot
```

No static AWS access keys are required on the EC2 instance.

## 5. IAM

The EC2 instance uses an IAM role named:

```text
TodoAssessment-EC2-Role
```

The role grants the deployment host the required Secrets Manager read operation for the database secret. The design intentionally avoids broad EC2-management permissions that are not required by the deployment script.

## 6. EC2

The EC2 instance hosts:

- Backend container
- Frontend container
- Prometheus
- Grafana
- Node Exporter
- cAdvisor

Application files are deployed under:

```text
/home/ubuntu/todolistassesment/
```

## 7. Nginx

Nginx runs on the EC2 host and is the intended public application entry point.

Current routing is:

```text
Client
  |
  v
Nginx :80
  |
  +---- / ------> Frontend :3000
  |
  +---- /api/ --> Backend :8081
```

The active Nginx configuration was validated with `nginx -t`. A duplicate backup server block was removed from `sites-enabled` so that conflicting server-name warnings no longer occur.

The current deployment has HTTP routing configured. Do not describe HTTPS as active unless TLS certificates and the HTTPS server block are configured and verified.

## 8. Security-Group Design

The intended design is:

### RDS security group

- TCP 3306
- Source: EC2 security group only
- No public database access

### EC2 security group

- HTTP/HTTPS only as required for public application access.
- SSH should be restricted to the administrator's trusted IP where practical.
- Monitoring ports should be restricted to approved administrative access.

The exact active security-group rules should be captured in the final AWS screenshots before submission.

## 9. Important Assumptions

The assessment requires EC2 + RDS and restricted access but does not explicitly require a multi-subnet/NAT-gateway architecture. The implementation therefore keeps the AWS footprint small as recommended by the assessment.

RDS high availability through Multi-AZ is an operational option rather than a claim about the current single-instance assessment environment. Backups/snapshots should be used according to the recovery requirements of the environment.
