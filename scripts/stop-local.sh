#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/.local-runtime"
PID_DIR="$RUNTIME_DIR/pids"
NGINX_PREFIX="$RUNTIME_DIR/nginx"
NGINX_DOCKER_CONTAINER_NAME="${NGINX_DOCKER_CONTAINER_NAME:-healthcare-local-nginx}"
POSTGRES_DOCKER_CONTAINER_NAME="${POSTGRES_DOCKER_CONTAINER_NAME:-healthcare-local-postgres}"
KAFKA_DOCKER_CONTAINER_NAME="${KAFKA_DOCKER_CONTAINER_NAME:-healthcare-local-kafka}"
LEGACY_NGINX_DOCKER_CONTAINER_NAME="nginx-healthCare"
LEGACY_POSTGRES_DOCKER_CONTAINER_NAME="healthcare-postgres"

DOCKER_BIN="${DOCKER_BIN:-$(command -v docker || true)}"
DOCKER_CONTEXT="${DOCKER_CONTEXT:-colima}"
if [ -z "$DOCKER_BIN" ]; then
  for candidate in /usr/local/bin/docker /opt/homebrew/bin/docker; do
    if [ -x "$candidate" ]; then
      DOCKER_BIN="$candidate"
      break
    fi
  done
fi

docker_cmd() {
  if [ -n "$DOCKER_CONTEXT" ]; then
    "$DOCKER_BIN" --context "$DOCKER_CONTEXT" "$@"
  else
    "$DOCKER_BIN" "$@"
  fi
}

stop_pid_file() {
  local pid_file="$1"
  if [ -f "$pid_file" ]; then
    local pid
    pid="$(cat "$pid_file")"
    if [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1; then
      kill "$pid" >/dev/null 2>&1 || true
    fi
    rm -f "$pid_file"
  fi
}

if command -v nginx >/dev/null 2>&1; then
  nginx -p "$NGINX_PREFIX" -c "$ROOT_DIR/gateway/nginx.local.conf" -s quit >/dev/null 2>&1 || true
fi

if [ -n "$DOCKER_BIN" ]; then
  docker_cmd rm -f "$NGINX_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
  docker_cmd rm -f "$POSTGRES_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
  docker_cmd rm -f "$KAFKA_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
  docker_cmd rm -f "$LEGACY_NGINX_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
  docker_cmd rm -f "$LEGACY_POSTGRES_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
fi

if [ -d "$PID_DIR" ]; then
  for pid_file in "$PID_DIR"/*.pid; do
    [ -e "$pid_file" ] || continue
    stop_pid_file "$pid_file"
  done
fi

echo "Local processes stopped"
