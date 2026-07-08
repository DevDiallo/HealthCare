#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/.local-runtime"
LOG_DIR="$RUNTIME_DIR/logs"
PID_DIR="$RUNTIME_DIR/pids"
NGINX_DOCKER_CONTAINER_NAME="${NGINX_DOCKER_CONTAINER_NAME:-healthcare-local-nginx}"
POSTGRES_DOCKER_CONTAINER_NAME="${POSTGRES_DOCKER_CONTAINER_NAME:-healthcare-local-postgres}"
LEGACY_NGINX_DOCKER_CONTAINER_NAME="nginx-healthCare"
LEGACY_POSTGRES_DOCKER_CONTAINER_NAME="healthcare-postgres"
JWT_SECRET_AUTH_BASE64="MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZg=="
JWT_SECRET_SERVICES_RAW="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

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

if [ -z "$DOCKER_BIN" ]; then
  echo "Docker CLI not found. Install Docker Desktop or set DOCKER_BIN."
  exit 1
fi

MVN_BIN="${MVN_BIN:-$(command -v mvn || true)}"
if [ -z "$MVN_BIN" ]; then
  for candidate in /opt/homebrew/bin/mvn /usr/local/bin/mvn /usr/bin/mvn "$HOME/.sdkman/candidates/maven/current/bin/mvn"; do
    if [ -x "$candidate" ]; then
      MVN_BIN="$candidate"
      break
    fi
  done
fi

if [ -z "$MVN_BIN" ]; then
  echo "Maven CLI not found. Install Maven or set MVN_BIN."
  exit 1
fi

NPM_BIN="${NPM_BIN:-$(command -v npm || true)}"
if [ -z "$NPM_BIN" ]; then
  for candidate in /opt/homebrew/bin/npm /usr/local/bin/npm /usr/bin/npm; do
    if [ -x "$candidate" ]; then
      NPM_BIN="$candidate"
      break
    fi
  done
fi

if [ -z "$NPM_BIN" ]; then
  echo "npm not found. Install Node.js/npm or set NPM_BIN."
  exit 1
fi

NODE_BIN="${NODE_BIN:-$(command -v node || true)}"
if [ -z "$NODE_BIN" ]; then
  for candidate in /opt/homebrew/bin/node /usr/local/bin/node /usr/bin/node; do
    if [ -x "$candidate" ]; then
      NODE_BIN="$candidate"
      break
    fi
  done
fi

if [ -z "$NODE_BIN" ]; then
  echo "Node.js not found. Install Node.js or set NODE_BIN."
  exit 1
fi

docker_cmd() {
  if [ -n "$DOCKER_CONTEXT" ]; then
    "$DOCKER_BIN" --context "$DOCKER_CONTEXT" "$@"
  else
    "$DOCKER_BIN" "$@"
  fi
}

mkdir -p "$LOG_DIR" "$PID_DIR"

docker_cmd rm -f "$LEGACY_NGINX_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
docker_cmd rm -f "$LEGACY_POSTGRES_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true

wait_port() {
  local port="$1"
  local retries="$2"
  local i=0
  while [ "$i" -lt "$retries" ]; do
    if nc -z 127.0.0.1 "$port" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done
  return 1
}

start_postgres_container() {
  docker_cmd run -d \
    --name "$POSTGRES_DOCKER_CONTAINER_NAME" \
    -e POSTGRES_USER=healthcare \
    -e POSTGRES_PASSWORD=healthcare \
    -e POSTGRES_DB=postgres \
    -p 5432:5432 \
    -v "$ROOT_DIR/db/init:/docker-entrypoint-initdb.d" \
    postgres:16-alpine >/dev/null
}

psql_in_postgres() {
  local sql="$1"
  local retries="${2:-15}"
  local i=0
  local out=""
  while [ "$i" -lt "$retries" ]; do
    out="$(docker_cmd exec -e PGPASSWORD=healthcare "$POSTGRES_DOCKER_CONTAINER_NAME" \
      psql -U healthcare -d postgres -tAc "$sql" 2>/dev/null || true)"
    if [ -n "$out" ]; then
      printf '%s' "$out"
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done
  return 1
}

psql_exec_retry() {
  local sql="$1"
  local retries="${2:-15}"
  local i=0
  while [ "$i" -lt "$retries" ]; do
    if docker_cmd exec -e PGPASSWORD=healthcare "$POSTGRES_DOCKER_CONTAINER_NAME" \
      psql -U healthcare -d postgres -c "$sql" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done
  return 1
}

start_service() {
  local name="$1"
  local path="$2"
  local port="$3"
  local db_name="$4"
  local jwt_secret="$5"

  if nc -z 127.0.0.1 "$port" >/dev/null 2>&1; then
    echo "$name already listening on $port"
    return 0
  fi

  (
    cd "$ROOT_DIR/$path"
    nohup env \
      DB_URL="jdbc:postgresql://localhost:5432/${db_name}" \
      DB_USERNAME="healthcare" \
      DB_PASSWORD="healthcare" \
      SERVER_PORT="$port" \
      SERVER_ADDRESS="0.0.0.0" \
      JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true" \
      JWT_SECRET="$jwt_secret" \
      "$MVN_BIN" -DskipTests spring-boot:run \
      > "$LOG_DIR/${name}.log" 2>&1 &
    echo $! > "$PID_DIR/${name}.pid"
  )
  echo "started $name"
}

# 1) Postgres container
if ! docker_cmd ps --format '{{.Names}}' | grep -q "^${POSTGRES_DOCKER_CONTAINER_NAME}$"; then
  if docker_cmd ps -a --format '{{.Names}}' | grep -q "^${POSTGRES_DOCKER_CONTAINER_NAME}$"; then
    docker_cmd start "$POSTGRES_DOCKER_CONTAINER_NAME" >/dev/null
  else
    start_postgres_container
  fi
fi

# Docker peut laisser un conteneur "dead" visible; on force un recreate si non-running.
postgres_running="$(docker_cmd inspect -f '{{if .State.Running}}1{{else}}0{{end}}' "$POSTGRES_DOCKER_CONTAINER_NAME" 2>/dev/null || echo 0)"
if [ "$postgres_running" != "1" ]; then
  docker_cmd rm -f "$POSTGRES_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
  start_postgres_container
fi

# Wait for postgres ready
local_ready=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60; do
  if docker_cmd exec "$POSTGRES_DOCKER_CONTAINER_NAME" pg_isready -U healthcare >/dev/null 2>&1; then
    local_ready=1
    break
  fi
  sleep 1
done
if [ "$local_ready" -ne 1 ]; then
  echo "Postgres not ready"
  exit 1
fi

# Ensure DBs exist
for db in healthcare_auth healthcare_hospital healthcare_patient healthcare_doctor healthcare_appointment healthcare_notification; do
  db_exists="$(psql_in_postgres "SELECT 1 FROM pg_database WHERE datname='${db}'" 20 || true)"
  if [ "$db_exists" != "1" ]; then
    if ! psql_exec_retry "CREATE DATABASE ${db};" 20; then
      echo "failed to ensure database ${db}"
      exit 1
    fi
  fi
done

# 2) Backend services
start_service auth-service backend/auth-service 8081 healthcare_auth "$JWT_SECRET_AUTH_BASE64"
start_service hospital-service backend/hospital-service 8082 healthcare_hospital "$JWT_SECRET_SERVICES_RAW"
start_service patient-service backend/patient-service 8083 healthcare_patient "$JWT_SECRET_SERVICES_RAW"
start_service doctor-service backend/doctor-service 8084 healthcare_doctor "$JWT_SECRET_SERVICES_RAW"
start_service appointment-service backend/appointment-service 8085 healthcare_appointment "$JWT_SECRET_SERVICES_RAW"
start_service notification-service backend/notification-service 8086 healthcare_notification "$JWT_SECRET_SERVICES_RAW"

# 3) Frontend
if nc -z 127.0.0.1 5173 >/dev/null 2>&1; then
  echo "frontend already listening on 5173"
else
  cd "$ROOT_DIR/frontend"
  if [ ! -d node_modules ]; then
    "$NPM_BIN" ci
  fi
  nohup "$NPM_BIN" run dev -- --host 0.0.0.0 --port 5173 > "$LOG_DIR/frontend.log" 2>&1 &
  echo $! > "$PID_DIR/frontend.pid"
  echo "started frontend"
fi

# Wait services ports
for port in 8081 8082 8083 8084 8085 8086 5173; do
  if ! wait_port "$port" 180; then
    echo "port $port not ready"
    exit 1
  fi
done

start_gateway_local_fallback() {
  nohup "$NODE_BIN" "$ROOT_DIR/scripts/local-gateway.js" > "$LOG_DIR/gateway.log" 2>&1 &
  echo $! > "$PID_DIR/gateway.pid"
  echo "started local gateway fallback"
}

docker_gateway_can_reach_host() {
  docker_cmd exec "$NGINX_DOCKER_CONTAINER_NAME" sh -lc 'nc -z host.docker.internal 8081 && nc -z host.docker.internal 8082 && nc -z host.docker.internal 8083 && nc -z host.docker.internal 8084 && nc -z host.docker.internal 8085 && nc -z host.docker.internal 8086 && nc -z host.docker.internal 5173' >/dev/null 2>&1
}

# 4) Gateway
docker_cmd rm -f "$NGINX_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
docker_cmd run -d \
  --name "$NGINX_DOCKER_CONTAINER_NAME" \
  -p 8080:8080 \
  -v "$ROOT_DIR/gateway/nginx.local.conf:/etc/nginx/nginx.conf:ro" \
  nginx:trixie-perl >/dev/null

if ! docker_gateway_can_reach_host; then
  echo "Docker gateway cannot reach host services; switching to local gateway fallback"
  docker_cmd rm -f "$NGINX_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
  start_gateway_local_fallback
fi

# Validate
if ! wait_port 8080 30; then
  echo "gateway not ready on 8080"
  exit 1
fi

curl -fsS http://localhost:8080/health

echo
echo "Application started successfully"
echo "Gateway: http://localhost:8080"
echo "Logs: $LOG_DIR"
