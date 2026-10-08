# Final Repository Checklist

## Application

- [ ] Existing application works
- [ ] No unnecessary business-logic changes
- [ ] Environment variables documented

## Docker

- [ ] Backend Dockerfile
- [ ] Frontend Dockerfile
- [ ] Backend `.dockerignore`
- [ ] Frontend `.dockerignore`
- [ ] Non-root runtime
- [ ] Health checks

## CI/CD

- [ ] Backend tests
- [ ] Frontend build
- [ ] Docker build
- [ ] SHA image tags
- [ ] Docker Hub push
- [ ] EC2 deployment
- [ ] Deployment health checks
- [ ] Rollback

## AWS

- [ ] EC2
- [ ] RDS MySQL
- [ ] RDS not publicly accessible
- [ ] RDS SG allows EC2 only
- [ ] EC2 IAM role
- [ ] Secrets Manager
- [ ] No static AWS keys

## Monitoring

- [ ] Prometheus
- [ ] Grafana
- [ ] Node Exporter
- [ ] cAdvisor
- [ ] Request rate
- [ ] Error rate
- [ ] Latency
- [ ] CPU
- [ ] Memory
- [ ] Disk
- [ ] Uptime
- [ ] Container restart/uptime
- [ ] Backend-down alert
- [ ] High CPU alert

## Documentation

- [ ] AWS architecture
- [ ] Architecture diagram
- [ ] Deployment
- [ ] Monitoring and operations
- [ ] Failure and rollback
- [ ] Security
- [ ] Testing
- [ ] Troubleshooting
- [ ] Project status
