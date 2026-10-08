# Monitoring and Operations

## 1. Monitoring Stack

The monitoring stack runs on EC2:

- Prometheus — metric collection and rule evaluation.
- Grafana — dashboards and alerting.
- Node Exporter — EC2 host metrics.
- cAdvisor — container metrics where supported.
- Spring Boot Actuator + Micrometer — application metrics.

## 2. Prometheus Targets

Configured targets:

```text
backend:8080/actuator/prometheus
node-exporter:9100/metrics
cadvisor:8080/metrics
```

## 3. Dashboard Coverage

The current Grafana dashboard covers:

| Metric | Purpose |
|---|---|
| Backend availability | Detect service outage |
| Request rate | Understand traffic/load |
| Error rate | Detect failed requests |
| EC2 CPU | Detect CPU saturation |
| EC2 memory | Detect memory pressure |
| EC2 disk | Detect disk exhaustion risk |
| JVM heap | Detect application memory pressure |
| JVM threads | Detect thread growth |
| JVM GC activity | Detect garbage-collection pressure |

## 4. Latency

Spring Boot currently exposes:

```text
http_server_requests_seconds_sum
http_server_requests_seconds_count
http_server_requests_seconds_max
```

The histogram bucket metric:

```text
http_server_requests_seconds_bucket
```

is not currently exposed.

Therefore the project does **not** claim a P95 latency metric. Average request latency can be calculated with:

```promql
sum(rate(http_server_requests_seconds_sum{job="todo-backend"}[5m]))
/
sum(rate(http_server_requests_seconds_count{job="todo-backend"}[5m]))
```

This is a valid average latency calculation, not a percentile.

## 5. Alerts

### Backend Down

Prometheus rule:

```promql
up{job="todo-backend"} < 1
```

The Grafana Backend Down alert was tested by stopping the backend and observing the alert enter `Firing`, followed by recovery to `Normal` after the service was restored.

### High EC2 CPU

Prometheus/Grafana expression:

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
```

The alert is configured for sustained high CPU. It is intended to avoid alerting on short-lived CPU spikes.

## 6. cAdvisor Limitation

cAdvisor is deployed and Prometheus can scrape its endpoint. However, the current EC2 Docker environment reports errors while identifying some Docker overlay filesystem layers. As a result, per-container cAdvisor metrics are not treated as a complete source of container restart/resource telemetry.

This limitation is documented instead of being hidden.

## 7. Uptime

Spring Boot exposes process uptime through metrics such as:

```text
process_uptime_seconds
```

This provides a reliable application-process uptime signal. It can be used to identify application restarts even when complete cAdvisor container metadata is unavailable.

## 8. Important Logs

### Application

```bash
docker compose logs --tail=100 backend
docker compose logs --tail=100 frontend
```

Look for:

- startup failures
- database authentication failures
- connection failures
- unhandled exceptions
- repeated restarts

### Nginx

```bash
sudo nginx -t
sudo nginx -T
sudo systemctl status nginx
```

### Monitoring

```bash
docker compose logs --tail=100 prometheus
docker compose logs --tail=100 grafana
docker logs --tail=100 node-exporter
docker logs --tail=100 cadvisor
```

## 9. Operational Detection Strategy

Problems should be detected through a combination of:

1. Deployment health checks.
2. Docker restart behavior.
3. Prometheus target health.
4. Grafana dashboards.
5. Service-down alerts.
6. CPU/resource alerts.
7. Application and Nginx logs.

The goal is to alert on actionable conditions rather than every minor metric fluctuation.
