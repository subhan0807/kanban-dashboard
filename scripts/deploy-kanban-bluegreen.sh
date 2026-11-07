
#!/bin/bash
set -Eeuo pipefail

IMAGE="subhan0807/kanban-dashboard"
TAG="${1:-}"

if [[ ! "$TAG" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Provide a numeric image tag."
    exit 1
fi

BLUE_PORT=8081
GREEN_PORT=8082
STATE_FILE="/etc/kanban-active-slot"
NGINX_CONF="/etc/nginx/sites-available/kanban-blue-test"

if [[ -f "$STATE_FILE" ]]; then
    ACTIVE=$(cat "$STATE_FILE")
else
    ACTIVE="green"
fi

if [[ "$ACTIVE" == "blue" ]]; then
    TARGET="green"
    PORT="$GREEN_PORT"
else
    TARGET="blue"
    PORT="$BLUE_PORT"
fi

CONTAINER="kanban-$TARGET"
PREVIOUS_PORT=$([[ "$ACTIVE" == "blue" ]] && echo "$BLUE_PORT" || echo "$GREEN_PORT")

echo "Active slot: $ACTIVE"
echo "Deploying image: $IMAGE:$TAG to $TARGET on port $PORT"

docker pull "$IMAGE:$TAG"
docker rm -f "$CONTAINER" 2>/dev/null || true

docker run -d \
    --name "$CONTAINER" \
    --restart unless-stopped \
    --memory=512m \
    --cpus=0.5 \
    -p "127.0.0.1:$PORT:8080" \
    "$IMAGE:$TAG"

echo "Waiting for $TARGET health..."

HEALTHY=0
for i in $(seq 1 30); do
    if docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null | grep -q healthy; then
        HEALTHY=1
        break
    fi
    sleep 2
done

if [[ "$HEALTHY" -ne 1 ]]; then
    echo "ERROR: New slot failed health check."
    docker logs "$CONTAINER"
    docker rm -f "$CONTAINER" || true
    exit 1
fi

echo "New slot is healthy. Switching Nginx traffic..."

cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

if ! nginx -t; then
    echo "ERROR: Nginx configuration failed."
    exit 1
fi

if ! systemctl reload nginx; then
    echo "ERROR: Nginx reload failed."
    exit 1
fi

if ! curl -fsS http://127.0.0.1/health >/dev/null; then
    echo "ERROR: Public health check failed. Restoring previous slot."
    sed -i "s|proxy_pass http://127.0.0.1:$PORT;|proxy_pass http://127.0.0.1:$PREVIOUS_PORT;|" "$NGINX_CONF"
    nginx -t && systemctl reload nginx
    exit 1
fi

echo "$TARGET" > "$STATE_FILE"

echo "SUCCESS: Traffic switched to $TARGET."
echo "Application health: healthy"
