#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE_TAG="${1:-latest}"
APP_DIR="${APP_DIR:-/opt/todo-summary-assistant}"
SECRET_ID="${TODO_SECRET_ID:-todo-summary-assistant/prod}"
CURRENT_TAG_FILE="$APP_DIR/.current_tag"

: "${DOCKERHUB_USERNAME:?DOCKERHUB_USERNAME must be set for deployment}"

cd "$APP_DIR"
PREVIOUS_TAG=""
if [ -f "$CURRENT_TAG_FILE" ]; then
  PREVIOUS_TAG="$(cat "$CURRENT_TAG_FILE")"
fi

echo "==> Preparing runtime secrets from AWS Secrets Manager"
command -v aws >/dev/null 2>&1 || { echo "AWS CLI is required on EC2." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required on EC2." >&2; exit 1; }

SECRET_JSON="$(aws secretsmanager get-secret-value --secret-id "$SECRET_ID" --query SecretString --output text)"
printf '%s' "$SECRET_JSON" | jq -e . >/dev/null

get_secret() {
  local key="$1"
  printf '%s' "$SECRET_JSON" | jq -er --arg key "$key" '.[$key] // empty'
}

cat > .env.runtime <<EOF
SPRING_DATASOURCE_URL=$(get_secret SPRING_DATASOURCE_URL)
SPRING_DATASOURCE_USERNAME=$(get_secret SPRING_DATASOURCE_USERNAME)
SPRING_DATASOURCE_PASSWORD=$(get_secret SPRING_DATASOURCE_PASSWORD)
COHERE_API_KEY=$(get_secret COHERE_API_KEY)
SLACK_WEBHOOK_URL=$(get_secret SLACK_WEBHOOK_URL)
CORS_ALLOWED_ORIGINS=$(printf '%s' "$SECRET_JSON" | jq -r '.CORS_ALLOWED_ORIGINS // "http://localhost:3000"')
SPRING_JPA_HIBERNATE_DDL_AUTO=$(printf '%s' "$SECRET_JSON" | jq -r '.SPRING_JPA_HIBERNATE_DDL_AUTO // "update"')
EOF

cat > .env.grafana <<EOF
GF_SECURITY_ADMIN_USER=$(printf '%s' "$SECRET_JSON" | jq -r '.GRAFANA_ADMIN_USER // "admin"')
GF_SECURITY_ADMIN_PASSWORD=$(get_secret GRAFANA_ADMIN_PASSWORD)
EOF
chmod 600 .env.runtime .env.grafana

export IMAGE_TAG
echo "==> Deploying image tag: $IMAGE_TAG"
docker compose pull backend frontend
docker compose up -d --remove-orphans

health_check() {
  for i in $(seq 1 30); do
    if curl -fsS http://127.0.0.1:8081/actuator/health >/dev/null && \
       curl -fsS http://127.0.0.1:3000/health >/dev/null; then
      return 0
    fi
    sleep 5
  done
  return 1
}

if ! health_check; then
  echo "==> New deployment failed health checks" >&2
  docker compose logs --tail=100 backend frontend || true

  if [ -n "$PREVIOUS_TAG" ] && [ "$PREVIOUS_TAG" != "$IMAGE_TAG" ]; then
    echo "==> Rolling back automatically to $PREVIOUS_TAG" >&2
    export IMAGE_TAG="$PREVIOUS_TAG"
    docker compose pull backend frontend
    docker compose up -d --remove-orphans
    if health_check; then
      echo "$PREVIOUS_TAG" > "$CURRENT_TAG_FILE"
      echo "Rollback successful." >&2
    else
      echo "Rollback health check failed; manual intervention required." >&2
    fi
  fi
  exit 1
fi

printf '%s\n' "$IMAGE_TAG" > "$CURRENT_TAG_FILE"
chmod 600 "$CURRENT_TAG_FILE"

echo "==> Deployment successful"
docker compose ps
docker image prune -f
