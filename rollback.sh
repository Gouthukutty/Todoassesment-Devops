#!/usr/bin/env bash
set -Eeuo pipefail

TAG="${1:?Usage: ./rollback.sh <previous-image-tag>}"
cd /opt/todo-summary-assistant
export IMAGE_TAG="$TAG"
docker compose pull backend frontend
docker compose up -d --remove-orphans
curl -fsS http://127.0.0.1:8081/actuator/health >/dev/null
curl -fsS http://127.0.0.1:3000/health >/dev/null
echo "Rolled back to $TAG"
