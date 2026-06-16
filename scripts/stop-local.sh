#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/.local-runtime"
PID_DIR="$RUNTIME_DIR/pids"
NGINX_PREFIX="$RUNTIME_DIR/nginx"

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

if [ -d "$PID_DIR" ]; then
  for pid_file in "$PID_DIR"/*.pid; do
    [ -e "$pid_file" ] || continue
    stop_pid_file "$pid_file"
  done
fi

echo "Local processes stopped"
