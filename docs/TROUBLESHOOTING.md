# Troubleshooting

## Backend Has No Database Password

Symptom:

```text
Access denied ... (using password: NO)
```

Cause:

The backend was started without the credential injection performed by `deploy.sh`.

Solution:

```bash
cd /home/ubuntu/todolistassesment
./deploy.sh "$(cat .current_tag)"
```

## Backend Health Check Fails

Check:

```bash
docker compose ps
docker compose logs --tail=100 backend
curl http://127.0.0.1:8081/actuator/health
```

Then verify:

- RDS availability
- database endpoint
- security group
- Secrets Manager
- IAM role

## Frontend Health Check Fails

Check:

```bash
docker compose ps
docker compose logs --tail=100 frontend
curl http://127.0.0.1:3000/health
```

## Nginx Problems

Check:

```bash
sudo nginx -t
sudo nginx -T
sudo systemctl status nginx
```

Look for duplicate/conflicting server blocks.

## Grafana Is Not Accessible

Do not immediately open Grafana to the entire internet.

Preferred method:

```bash
ssh -i YOUR_KEY.pem -L 3001:localhost:3001 ubuntu@EC2_HOST
```

Then open:

```text
http://localhost:3001
```

## Prometheus Has No Application Metrics

Check:

```bash
curl http://127.0.0.1:8081/actuator/prometheus
```

Then inspect the Prometheus target configuration.

## cAdvisor Has No Container Metrics

Verify the Docker runtime and cAdvisor compatibility.

Do not change the Docker storage driver solely to force cAdvisor to work without evaluating the impact.

Use verified Spring Boot and Node Exporter metrics for monitoring that does not depend on cAdvisor.
