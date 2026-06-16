#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/.local-runtime"
LOG_DIR="$RUNTIME_DIR/logs"
PID_DIR="$RUNTIME_DIR/pids"

mkdir -p "$LOG_DIR" "$PID_DIR"

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
      JWT_SECRET="$jwt_secret" \
      mvn -DskipTests spring-boot:run \
      > "$LOG_DIR/${name}.log" 2>&1 &
    echo $! > "$PID_DIR/${name}.pid"
  )
  echo "started $name"
}

# 1) Postgres container
if ! docker ps --format '{{.Names}}' | grep -q '^healthcare-postgres$'; then
  if docker ps -a --format '{{.Names}}' | grep -q '^healthcare-postgres$'; then
    docker start healthcare-postgres >/dev/null
  else
    docker run -d \
      --name healthcare-postgres \
      -e POSTGRES_USER=healthcare \
      -e POSTGRES_PASSWORD=healthcare \
      -e POSTGRES_DB=postgres \
      -p 5432:5432 \
      -v "$ROOT_DIR/db/init:/docker-entrypoint-initdb.d" \
      postgres:16-alpine >/dev/null
  fi
fi

# Wait for postgres ready
local_ready=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60; do
  if docker exec healthcare-postgres pg_isready -U healthcare >/dev/null 2>&1; then
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
  docker exec -e PGPASSWORD=healthcare healthcare-postgres \
    psql -U healthcare -d postgres -tc "SELECT 1 FROM pg_database WHERE datname='${db}'" | grep -q 1 || \
  docker exec -e PGPASSWORD=healthcare healthcare-postgres \
    psql -U healthcare -d postgres -c "CREATE DATABASE ${db};" >/dev/null
done

# 2) Backend services
start_service auth-service backend/auth-service 8081 healthcare_auth MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZg==
start_service hospital-service backend/hospital-service 8082 healthcare_hospital 0123456789ABCDEF0123456789ABCDEF
start_service patient-service backend/patient-service 8083 healthcare_patient 0123456789ABCDEF0123456789ABCDEF
start_service doctor-service backend/doctor-service 8084 healthcare_doctor 0123456789ABCDEF0123456789ABCDEF
start_service appointment-service backend/appointment-service 8085 healthcare_appointment 0123456789ABCDEF0123456789ABCDEF
start_service notification-service backend/notification-service 8086 healthcare_notification 0123456789ABCDEF0123456789ABCDEF

# 3) Frontend
if nc -z 127.0.0.1 5173 >/dev/null 2>&1; then
  echo "frontend already listening on 5173"
else
  cd "$ROOT_DIR/frontend"
  if [ ! -d node_modules ]; then
    npm ci
  fi
  nohup npm run dev -- --host 127.0.0.1 --port 5173 > "$LOG_DIR/frontend.log" 2>&1 &
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

# 4) Gateway in Docker
if ! docker ps --format '{{.Names}}' | grep -q '^nginx-healthCare$'; then
  docker rm -f nginx-healthCare >/dev/null 2>&1 || true
  docker run -d \
    --name nginx-healthCare \
    -p 8080:8080 \
    -v "$ROOT_DIR/gateway/nginx.local.conf:/etc/nginx/nginx.conf:ro" \
    nginx:trixie-perl >/dev/null
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
