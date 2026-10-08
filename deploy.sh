#!/bin/bash
set -euo pipefail

# ============================================================
# Todo Assessment - Production Deployment Script
# ============================================================

APP_DIR="/home/ubuntu/todolistassesment"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

AWS_REGION="ap-south-2"
SECRET_ID="todoassessment/rds"

IMAGE_TAG="${1:-latest}"

cd "$APP_DIR"

echo "============================================================"
echo "Starting deployment"
echo "Image tag: $IMAGE_TAG"
echo "============================================================"

# ------------------------------------------------------------
# 1. Validate required commands
# ------------------------------------------------------------

command -v docker >/dev/null 2>&1 || {
    echo "ERROR: Docker is not installed."
    exit 1
}

command -v aws >/dev/null 2>&1 || {
    echo "ERROR: AWS CLI is not installed."
    exit 1
}

command -v python3 >/dev/null 2>&1 || {
    echo "ERROR: Python3 is not installed."
    exit 1
}

command -v curl >/dev/null 2>&1 || {
    echo "ERROR: curl is not installed."
    exit 1
}

# ------------------------------------------------------------
# 2. Retrieve database credentials from AWS Secrets Manager
# ------------------------------------------------------------

echo "Retrieving database credentials from AWS Secrets Manager..."

SECRET_STRING=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_ID" \
    --region "$AWS_REGION" \
    --query SecretString \
    --output text)

if [ -z "$SECRET_STRING" ] || [ "$SECRET_STRING" = "None" ]; then
    echo "ERROR: Failed to retrieve database secret."
    exit 1
fi

export SPRING_DATASOURCE_USERNAME=$(printf '%s' "$SECRET_STRING" | \
    python3 -c 'import json, sys; print(json.load(sys.stdin)["username"])')

export SPRING_DATASOURCE_PASSWORD=$(printf '%s' "$SECRET_STRING" | \
    python3 -c 'import json, sys; print(json.load(sys.stdin)["password"])')

unset SECRET_STRING

if [ -z "${SPRING_DATASOURCE_USERNAME:-}" ]; then
    echo "ERROR: Database username is empty."
    exit 1
fi

if [ -z "${SPRING_DATASOURCE_PASSWORD:-}" ]; then
    echo "ERROR: Database password is empty."
    exit 1
fi

echo "Database credentials retrieved successfully."

# ------------------------------------------------------------
# 3. Save current version for rollback
# ------------------------------------------------------------

CURRENT_TAG_FILE="$APP_DIR/.current_tag"
PREVIOUS_TAG=""

if [ -f "$CURRENT_TAG_FILE" ]; then
    PREVIOUS_TAG=$(cat "$CURRENT_TAG_FILE")
fi

echo "Previous successful image tag: ${PREVIOUS_TAG:-none}"

# ------------------------------------------------------------
# 4. Pull new Docker images
# ------------------------------------------------------------

export IMAGE_TAG="$IMAGE_TAG"

echo "Pulling backend image..."
docker compose -f "$COMPOSE_FILE" pull backend

echo "Pulling frontend image..."
docker compose -f "$COMPOSE_FILE" pull frontend

# ------------------------------------------------------------
# 5. Deploy new containers
# ------------------------------------------------------------

echo "Starting new application version..."

docker compose \
    -f "$COMPOSE_FILE" \
    up -d --remove-orphans

echo "Containers started."

# ------------------------------------------------------------
# 6. Backend health check
# ------------------------------------------------------------

echo "Checking backend health..."

BACKEND_OK=false

for i in {1..30}; do

    if curl -fsS http://127.0.0.1:8081/actuator/health >/dev/null 2>&1; then
        BACKEND_OK=true
        echo "Backend health check passed."
        break
    fi

    echo "Backend not ready yet... attempt $i/30"
    sleep 5

done

# ------------------------------------------------------------
# 7. Frontend health check
# ------------------------------------------------------------

echo "Checking frontend health..."

FRONTEND_OK=false

for i in {1..30}; do

    if curl -fsS http://127.0.0.1:3000/health >/dev/null 2>&1; then
        FRONTEND_OK=true
        echo "Frontend health check passed."
        break
    fi

    echo "Frontend not ready yet... attempt $i/30"
    sleep 5

done

# ------------------------------------------------------------
# 8. Validate deployment
# ------------------------------------------------------------

if [ "$BACKEND_OK" = true ] && [ "$FRONTEND_OK" = true ]; then

    echo "============================================================"
    echo "DEPLOYMENT SUCCESSFUL"
    echo "Image tag: $IMAGE_TAG"
    echo "============================================================"

    echo "$IMAGE_TAG" > "$CURRENT_TAG_FILE"

    exit 0
fi

# ------------------------------------------------------------
# 9. Deployment failed
# ------------------------------------------------------------

echo "============================================================"
echo "DEPLOYMENT FAILED"
echo "============================================================"

echo "Current container status:"
docker compose -f "$COMPOSE_FILE" ps || true

echo ""
echo "Recent backend logs:"
docker compose -f "$COMPOSE_FILE" logs --tail=50 backend || true

echo ""
echo "Recent frontend logs:"
docker compose -f "$COMPOSE_FILE" logs --tail=50 frontend || true

# ------------------------------------------------------------
# 10. Automatic rollback
# ------------------------------------------------------------

if [ -z "$PREVIOUS_TAG" ]; then

    echo "No previous successful deployment found."
    echo "Cannot perform automatic rollback."

    exit 1
fi

if [ "$PREVIOUS_TAG" = "$IMAGE_TAG" ]; then

    echo "Previous tag is the same as current tag."
    echo "Cannot perform rollback."

    exit 1
fi

echo "============================================================"
echo "STARTING AUTOMATIC ROLLBACK"
echo "Rollback image tag: $PREVIOUS_TAG"
echo "============================================================"

export IMAGE_TAG="$PREVIOUS_TAG"

echo "Pulling previous backend image..."
docker compose -f "$COMPOSE_FILE" pull backend

echo "Pulling previous frontend image..."
docker compose -f "$COMPOSE_FILE" pull frontend

echo "Starting previous application version..."

docker compose \
    -f "$COMPOSE_FILE" \
    up -d --remove-orphans

# ------------------------------------------------------------
# 11. Rollback backend health check
# ------------------------------------------------------------

echo "Checking rollback backend health..."

ROLLBACK_BACKEND_OK=false

for i in {1..30}; do

    if curl -fsS http://127.0.0.1:8081/actuator/health >/dev/null 2>&1; then
        ROLLBACK_BACKEND_OK=true
        echo "Rollback backend health check passed."
        break
    fi

    echo "Rollback backend not ready... attempt $i/30"
    sleep 5

done

# ------------------------------------------------------------
# 12. Rollback frontend health check
# ------------------------------------------------------------

echo "Checking rollback frontend health..."

ROLLBACK_FRONTEND_OK=false

for i in {1..30}; do

    if curl -fsS http://127.0.0.1:3000/health >/dev/null 2>&1; then
        ROLLBACK_FRONTEND_OK=true
        echo "Rollback frontend health check passed."
        break
    fi

    echo "Rollback frontend not ready... attempt $i/30"
    sleep 5

done

# ------------------------------------------------------------
# 13. Validate rollback
# ------------------------------------------------------------

if [ "$ROLLBACK_BACKEND_OK" = true ] && [ "$ROLLBACK_FRONTEND_OK" = true ]; then

    echo "$PREVIOUS_TAG" > "$CURRENT_TAG_FILE"

    echo "============================================================"
    echo "ROLLBACK SUCCESSFUL"
    echo "Restored image tag: $PREVIOUS_TAG"
    echo "============================================================"

    exit 1

fi

# ------------------------------------------------------------
# 14. Rollback failed
# ------------------------------------------------------------

echo "============================================================"
echo "CRITICAL ERROR"
echo "ROLLBACK FAILED"
echo "============================================================"

echo "Current container status:"
docker compose -f "$COMPOSE_FILE" ps || true

echo ""
echo "Backend logs:"
docker compose -f "$COMPOSE_FILE" logs --tail=100 backend || true

echo ""
echo "Frontend logs:"
docker compose -f "$COMPOSE_FILE" logs --tail=100 frontend || true

exit 1