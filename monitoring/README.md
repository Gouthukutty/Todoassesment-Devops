# Monitoring Configuration

Monitoring configuration belongs here.

Current monitoring stack:
- Prometheus
- Grafana
- Node Exporter
- cAdvisor

Prometheus configuration:
`monitoring/prometheus/prometheus.yml`

Dashboard and alert details:
`docs/MONITORING_AND_OPERATIONS.md`

TODO:
- Add finalized Grafana dashboard export JSON.
- Add finalized alert provisioning files if desired.
- Verify latency metric.
- Verify container restart metric.
