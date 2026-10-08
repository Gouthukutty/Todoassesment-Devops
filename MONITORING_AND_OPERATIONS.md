# Monitoring and Operations

## 1. Monitoring Overview

The application is monitored using Prometheus and Grafana.

The monitoring setup collects information about:

- Backend availability
- EC2 CPU usage
- EC2 memory usage
- EC2 disk usage
- Backend request rate
- Backend error rate
- Backend JVM heap usage
- Backend JVM threads
- Backend garbage collection activity

The monitoring stack contains:

- Prometheus
- Grafana
- Node Exporter
- cAdvisor
- Spring Boot Actuator
- Micrometer Prometheus metrics

---

## 2. Monitoring Architecture

```text
                    +------------------+
                    |   Spring Boot    |
                    |     Backend      |
                    +--------+---------+
                             |
                             | Application metrics
                             v
                    +------------------+
                    |    Prometheus     |
                    +--------+---------+
                             |
                             | Metrics
                             v
                    +------------------+
                    |     Grafana       |
                    +------------------+

        EC2 System Metrics
                 |
                 v
          +--------------+
          | Node Exporter|
          +--------------+
                 |
                 v
             Prometheus

        Docker Metrics
                 |
                 v
            +---------+
            | cAdvisor|
            +---------+
                 |
                 v
             Prometheus
```

---

## 3. Prometheus

Prometheus collects metrics from the application and EC2 server.

The main monitored targets are:

- Spring Boot backend
- Node Exporter
- cAdvisor

The Prometheus configuration is stored in:

```text
monitoring/prometheus/prometheus.yml
```

Prometheus runs on port:

```text
9090
```

Prometheus can be checked using:

```bash
docker compose ps prometheus
```

Prometheus logs can be checked using:

```bash
docker compose logs --tail=100 prometheus
```

---

## 4. Spring Boot Application Metrics

The backend uses Spring Boot Actuator and Micrometer to expose application metrics.

The Prometheus metrics endpoint is:

```text
/actuator/prometheus
```

The application health endpoint is:

```text
/actuator/health
```

The backend exposes metrics such as:

- HTTP request count
- HTTP request duration
- HTTP response status
- JVM memory
- JVM threads
- JVM garbage collection
- Application process information

Example Prometheus query for backend requests:

```promql
sum(rate(http_server_requests_seconds_count{job="todo-backend"}[5m]))
```

---

## 5. Node Exporter

Node Exporter collects EC2 server-level metrics.

It provides information about:

- CPU
- Memory
- Disk
- System resources

Node Exporter runs on port:

```text
9100
```

It is used by Prometheus to collect EC2 infrastructure metrics.

---

## 6. cAdvisor

cAdvisor is included in the monitoring stack to provide Docker container metrics.

It is configured to collect container-related information from the Docker host.

However, on the current EC2 environment, cAdvisor does not expose all Docker container-level metrics because of the host's Docker storage and cgroup configuration.

The EC2 server uses:

- Docker `overlayfs`
- cgroup v2
- systemd cgroup driver

Therefore, container-specific cAdvisor metrics are not currently relied upon for the main dashboard.

Node Exporter and Spring Boot application metrics are used as the primary monitoring sources.

---

# 7. Grafana Dashboard

Grafana is used to visualize the metrics collected by Prometheus.

Grafana runs on:

```text
3001
```

The dashboard contains the following panels.

### Panel 1 — Backend Availability

Prometheus query:

```promql
up{job="todo-backend"}
```

This shows whether the backend is available.

Expected value:

```text
1 = Available
0 = Unavailable
```

---

### Panel 2 — EC2 CPU Usage

Prometheus query:

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

This shows the percentage of CPU being used on the EC2 server.

---

### Panel 3 — EC2 Memory Usage

Prometheus query:

```promql
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
```

This shows the percentage of EC2 memory currently being used.

---

### Panel 4 — EC2 Disk Usage

Prometheus query:

```promql
100 * (
  1 -
  (
    node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs|overlay"}
    /
    node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs|overlay"}
  )
)
```

This shows the percentage of disk space being used.

---

### Panel 5 — Backend Request Rate

Prometheus query:

```promql
sum(rate(http_server_requests_seconds_count{job="todo-backend"}[5m]))
```

This shows the number of backend requests being received per second.

---

### Panel 6 — Backend Error Rate

Prometheus query:

```promql
sum(
  rate(
    http_server_requests_seconds_count{
      job="todo-backend",
      status=~"4..|5.."
    }[5m]
  )
) or vector(0)
```

This shows the rate of HTTP 4xx and 5xx responses.

---

### Panel 7 — Backend JVM Heap Usage

Prometheus query:

```promql
100 * (
  sum(jvm_memory_used_bytes{job="todo-backend",area="heap"})
  /
  sum(jvm_memory_max_bytes{job="todo-backend",area="heap"})
)
```

This shows the percentage of JVM heap memory being used.

---

### Panel 8 — Backend JVM Threads

Prometheus query:

```promql
sum(jvm_threads_live_threads{job="todo-backend"})
```

This shows the number of active JVM threads.

---

### Panel 9 — Backend Garbage Collection Activity

Prometheus query:

```promql
sum(rate(jvm_gc_pause_seconds_count{job="todo-backend"}[5m]))
```

This shows JVM garbage collection activity.

---

# 8. Alerts

Two meaningful alerts are configured in Grafana.

## Alert 1 — Backend Down

The alert checks:

```promql
up{job="todo-backend"}
```

Condition:

```text
Below 1
```

The alert is triggered when the backend remains unavailable for at least one minute.

Summary:

```text
Backend application is down
```

Description:

```text
The Todo Summary Assistant backend has been unavailable for at least 1 minute.
```

---

## Alert 2 — High EC2 CPU

The alert uses:

```promql
100 - (
  avg by (instance) (
    rate(node_cpu_seconds_total{mode="idle"}[5m])
  ) * 100
)
```

Condition:

```text
Above 80%
```

The alert is triggered when EC2 CPU usage remains above 80% for at least five minutes.

Summary:

```text
EC2 CPU usage is high
```

Description:

```text
EC2 CPU usage has remained above 80% for at least 5 minutes.
```

---

# 9. Alert Testing

The backend availability alert was tested by intentionally stopping the backend container.

The test process was:

1. Stop the backend container.
2. Wait for the Grafana alert evaluation.
3. Verify that the Backend Down alert changes to `Firing`.
4. Restore the application.
5. Verify that the alert returns to `Normal`.

The application was restored using the deployment script:

```bash
./deploy.sh "$(cat .current_tag)"
```

This confirms that the backend availability alert is working.

The high CPU alert is configured with an 80% threshold and a five-minute pending period.

---

# 10. Application Health Checks

The backend provides a health endpoint:

```text
/actuator/health
```

The frontend provides:

```text
/health
```

The deployment script checks both endpoints after deployment.

The deployment is considered successful only when both health checks pass.

If the health checks fail, the deployment script attempts to restore the previous working version.

---

# 11. Operational Checks

## Check all containers

```bash
docker compose ps
```

## Check backend status

```bash
docker compose ps backend
```

## Check frontend status

```bash
docker compose ps frontend
```

## Check Prometheus status

```bash
docker compose ps prometheus
```

## Check Grafana status

```bash
docker compose ps grafana
```

## Check backend logs

```bash
docker compose logs --tail=100 backend
```

## Check frontend logs

```bash
docker compose logs --tail=100 frontend
```

## Check Prometheus logs

```bash
docker compose logs --tail=100 prometheus
```

## Check Grafana logs

```bash
docker compose logs --tail=100 grafana
```

---

# 12. Deployment Verification

After every deployment, verify:

1. Backend container is running.
2. Frontend container is running.
3. Backend health check is successful.
4. Frontend health check is successful.
5. Prometheus is running.
6. Grafana is running.
7. Backend metrics are available.
8. No unexpected errors are present in the application logs.

The deployment script performs backend and frontend health checks automatically.

---

# 13. Troubleshooting

## Backend Is Not Running

Check:

```bash
docker compose ps backend
```

Then check logs:

```bash
docker compose logs --tail=100 backend
```

If the deployment failed, check the current working version:

```bash
cat .current_tag
```

The previous working version can be redeployed using:

```bash
./deploy.sh "$(cat .current_tag)"
```

---

## Frontend Is Not Running

Check:

```bash
docker compose ps frontend
```

Then check:

```bash
docker compose logs --tail=100 frontend
```

---

## Prometheus Is Not Showing Metrics

Check Prometheus:

```bash
docker compose ps prometheus
```

Check logs:

```bash
docker compose logs --tail=100 prometheus
```

Verify that the backend metrics endpoint is available:

```text
/actuator/prometheus
```

---

## Grafana Is Not Available

Check:

```bash
docker compose ps grafana
```

Check logs:

```bash
docker compose logs --tail=100 grafana
```

Grafana runs on port:

```text
3001
```

For security, Grafana does not need to be permanently exposed to the public internet.

An SSH tunnel can be used when administrative access is required.

---

# 14. Monitoring and Security

Monitoring services should not be unnecessarily exposed to the public internet.

The production environment should keep administrative monitoring interfaces restricted.

The database is not publicly accessible.

RDS access is restricted to the EC2 security group on port 3306.

Application secrets are retrieved from AWS Secrets Manager rather than being stored in source code.

---

# 15. Operational Summary

The monitoring setup provides visibility into both application and infrastructure health.

Application monitoring is provided through:

- Spring Boot Actuator
- Micrometer
- Prometheus
- Grafana

Infrastructure monitoring is provided through:

- Node Exporter
- Prometheus
- Grafana

Alerting is provided through Grafana for:

- Backend availability
- High EC2 CPU usage

The deployment process also performs health checks and supports rollback to the previous working Docker image version when a deployment fails.
