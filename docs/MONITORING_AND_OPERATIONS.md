# Monitoring and Operations

## 1. Monitoring Architecture

```text
Spring Boot
    |
    | /actuator/prometheus
    v
Prometheus <---- Node Exporter
    |
    +---------- cAdvisor
    |
    v
Grafana
```

## 2. Monitoring Components

### Prometheus

Collects application and infrastructure metrics.

### Grafana

Provides dashboards and alerting.

### Node Exporter

Provides EC2 host metrics including CPU, memory and filesystem metrics.

### cAdvisor

Provides Docker/container metrics where compatible with the Docker runtime.

### Spring Boot Actuator

Provides application health and Prometheus metrics.

## 3. Required Dashboard Coverage

The dashboard should cover:

- Backend availability
- Request rate
- Error rate
- Request latency
- EC2 CPU
- EC2 memory
- EC2 disk
- Application uptime
- Container restart/uptime information where reliable metrics are available

## 4. Current Dashboard Queries

### Backend Availability

```promql
up{job="todo-backend"}
```

### EC2 CPU

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### EC2 Memory

```promql
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
```

### EC2 Disk

```promql
100 * (1 - (node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs|overlay"}))
```

### Backend Request Rate

```promql
sum(rate(http_server_requests_seconds_count{job="todo-backend"}[5m]))
```

### Backend Error Rate

```promql
sum(rate(http_server_requests_seconds_count{job="todo-backend",status=~"4..|5.."}[5m])) or vector(0)
```

### JVM Heap Usage

```promql
100 * (sum(jvm_memory_used_bytes{job="todo-backend",area="heap"}) / sum(jvm_memory_max_bytes{job="todo-backend",area="heap"}))
```

### JVM Threads

```promql
sum(jvm_threads_live_threads{job="todo-backend"})
```

### GC Activity

```promql
sum(rate(jvm_gc_pause_seconds_count{job="todo-backend"}[5m]))
```

## 5. Latency Panel

Preferred query for P95 latency, if the histogram metric is available:

```promql
histogram_quantile(
  0.95,
  sum by (le) (
    rate(http_server_requests_seconds_bucket{job="todo-backend"}[5m])
  )
)
```

Verify the metric exists before relying on the panel.

## 6. Uptime

Application process uptime can be represented with:

```promql
process_uptime_seconds{job="todo-backend"}
```

## 7. Alerts

### Backend Down

Query:

```promql
up{job="todo-backend"}
```

Condition:

```text
Below 1
```

Recommended configuration:

- Evaluation: 1 minute
- Pending: 1 minute

Summary:

```text
Backend application is down
```

Description:

```text
The Todo Summary Assistant backend has been unavailable for at least 1 minute.
```

### High EC2 CPU

Query:

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

Condition:

```text
Above 80
```

Recommended configuration:

- Evaluation: 1 minute
- Pending: 5 minutes

Summary:

```text
EC2 CPU usage is high
```

Description:

```text
EC2 CPU usage has remained above 80% for at least 5 minutes.
```

## 8. Alert Validation

Backend-down alert can be tested by stopping the backend container:

```bash
docker stop todo-backend
```

Confirm the alert changes to Firing.

Restore the application through the deployment procedure:

```bash
cd /home/ubuntu/todolistassesment
./deploy.sh "$(cat .current_tag)"
```

Confirm that the alert returns to Normal.

## 9. cAdvisor Limitation

cAdvisor is included in the monitoring stack, but container-specific metrics must be verified against the EC2 Docker runtime.

If cAdvisor does not expose reliable container metrics, do not claim that container restart metrics are available from cAdvisor.

The architecture can still use:

- Spring Boot metrics
- Prometheus
- Node Exporter
- Grafana

for the verified monitoring requirements.

## 10. Security

Do not expose Grafana publicly unless required.

Preferred access is through an SSH tunnel or a restricted administrative security-group rule.

Do not expose Prometheus or cAdvisor publicly without a specific operational requirement.

## 11. Operations

Useful commands:

```bash
docker compose ps
docker compose logs --tail=100 backend
docker compose logs --tail=100 frontend
docker stats
df -h
free -h
uptime
```

Check Nginx:

```bash
sudo systemctl status nginx
sudo nginx -t
sudo nginx -T
```
