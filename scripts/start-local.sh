#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/.local-runtime"
LOG_DIR="$RUNTIME_DIR/logs"
PID_DIR="$RUNTIME_DIR/pids"
NGINX_PREFIX="$RUNTIME_DIR/nginx"
NGINX_DOCKER_CONTAINER_NAME="${NGINX_DOCKER_CONTAINER_NAME:-healthcare-local-nginx}"
NGINX_DOCKER_IMAGE="${NGINX_DOCKER_IMAGE:-nginx:1.27-alpine}"
POSTGRES_DOCKER_CONTAINER_NAME="${POSTGRES_DOCKER_CONTAINER_NAME:-healthcare-local-postgres}"
POSTGRES_DOCKER_IMAGE="${POSTGRES_DOCKER_IMAGE:-postgres:16-alpine}"
POSTGRES_DOCKER_VOLUME="$RUNTIME_DIR/postgres-data"
KAFKA_DOCKER_CONTAINER_NAME="${KAFKA_DOCKER_CONTAINER_NAME:-healthcare-local-kafka}"
KAFKA_DOCKER_IMAGE="${KAFKA_DOCKER_IMAGE:-apache/kafka:latest}"
KAFKA_DOCKER_VOLUME="$RUNTIME_DIR/kafka-data"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USERNAME="${DB_USERNAME:-healthcare}"
DB_PASSWORD="${DB_PASSWORD:-healthcare}"
WAIT_PORT_RETRIES="${WAIT_PORT_RETRIES:-180}"
JAVA_HOME_FALLBACK_21="${JAVA_HOME_FALLBACK_21:-$HOME/Library/Application Support/Code/User/globalStorage/pleiades.java-extension-pack-jdk/java/21}"
KAFKA_BOOTSTRAP_SERVERS="${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}"
APPOINTMENT_EVENTS_TOPIC="${APPOINTMENT_EVENTS_TOPIC:-appointment-events}"

JWT_SECRET_AUTH="${JWT_SECRET_AUTH:-MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZg==}"
JWT_SECRET_SERVICES="${JWT_SECRET_SERVICES:-0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef}"

mkdir -p "$LOG_DIR" "$PID_DIR" "$NGINX_PREFIX/logs" "$NGINX_PREFIX/client_body_temp" "$NGINX_PREFIX/proxy_temp" "$NGINX_PREFIX/fastcgi_temp" "$NGINX_PREFIX/uwsgi_temp" "$NGINX_PREFIX/scgi_temp"
mkdir -p "$POSTGRES_DOCKER_VOLUME"
mkdir -p "$KAFKA_DOCKER_VOLUME"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    exit 1
  fi
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

docker_ready() {
  has_cmd docker && docker info >/dev/null 2>&1
}

java_major() {
  local java_bin="$1"
  "$java_bin" -version 2>&1 | /usr/bin/head -n 1 | /usr/bin/sed -E 's/.*version "([0-9]+).*/\1/'
}

resolve_java_home() {
  if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/java" ]]; then
    local major
    major="$(java_major "$JAVA_HOME/bin/java")"
    if [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 21 )); then
      return 0
    fi
  fi

  if [[ -x "$JAVA_HOME_FALLBACK_21/bin/java" ]]; then
    JAVA_HOME="$JAVA_HOME_FALLBACK_21"
    export JAVA_HOME
    return 0
  fi

  if command -v /usr/libexec/java_home >/dev/null 2>&1; then
    local detected
    detected="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
    if [[ -n "$detected" && -x "$detected/bin/java" ]]; then
      local major
      major="$(java_major "$detected/bin/java")"
      if [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 21 )); then
        JAVA_HOME="$detected"
        export JAVA_HOME
        return 0
      fi
    fi
  fi

  echo "Java 21 est requis. Configure JAVA_HOME vers un JDK 21 puis relance."
  echo "Exemple: export JAVA_HOME=\"$JAVA_HOME_FALLBACK_21\""
  return 1
}

port_open() {
  nc -z 127.0.0.1 "$1" >/dev/null 2>&1
}

stop_existing() {
  /bin/bash "$ROOT_DIR/scripts/stop-local.sh" >/dev/null 2>&1 || true
}

create_databases_if_possible() {
  if command -v psql >/dev/null 2>&1; then
    export PGPASSWORD="$DB_PASSWORD"
    local dbs=(healthcare_auth healthcare_hospital healthcare_patient healthcare_doctor healthcare_appointment healthcare_notification)
    for db in "${dbs[@]}"; do
      psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname='${db}'" | grep -q 1 || \
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -c "CREATE DATABASE ${db};" >/dev/null
    done
    unset PGPASSWORD
  else
    echo "psql not found: skipping automatic database creation"
  fi
}

create_databases_in_container() {
  local container_name="$1"
  local dbs=(healthcare_auth healthcare_hospital healthcare_patient healthcare_doctor healthcare_appointment healthcare_notification)

  local retries=60
  while (( retries > 0 )); do
    if docker exec "$container_name" pg_isready -U "$DB_USERNAME" -d postgres >/dev/null 2>&1; then
      break
    fi
    sleep 1
    retries=$((retries - 1))
  done

  if (( retries == 0 )); then
    echo "Timeout waiting for PostgreSQL inside container $container_name"
    return 1
  fi

  for db in "${dbs[@]}"; do
    docker exec \
      -e PGPASSWORD="$DB_PASSWORD" \
      "$container_name" \
      psql -U "$DB_USERNAME" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname='${db}'" \
      | grep -q 1 || \
      docker exec \
      -e PGPASSWORD="$DB_PASSWORD" \
      "$container_name" \
      psql -U "$DB_USERNAME" -d postgres -c "CREATE DATABASE ${db};" >/dev/null
  done
}

wait_port() {
  local port="$1"
  local name="$2"
  local retries="$WAIT_PORT_RETRIES"
  while (( retries > 0 )); do
    if nc -z 127.0.0.1 "$port" >/dev/null 2>&1; then
      echo "$name is ready on port $port"
      return 0
    fi
    sleep 1
    retries=$((retries - 1))
  done
  echo "Timeout waiting for $name on port $port"
  return 1
}

start_service() {
  local name="$1"
  local path="$2"
  local port="$3"
  local db_name="$4"
  local jwt_secret="$5"
  local patient_service_base_url="${6:-}"
  local doctor_service_base_url="${7:-}"
  local enable_kafka="${8:-false}"

  (
    cd "$ROOT_DIR/$path"
    nohup env \
      JAVA_HOME="$JAVA_HOME" \
      PATH="$JAVA_HOME/bin:$PATH" \
      DB_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${db_name}" \
      DB_USERNAME="$DB_USERNAME" \
      DB_PASSWORD="$DB_PASSWORD" \
      SERVER_PORT="$port" \
      JWT_SECRET="$jwt_secret" \
      ${patient_service_base_url:+PATIENT_SERVICE_BASE_URL="$patient_service_base_url"} \
      ${doctor_service_base_url:+DOCTOR_SERVICE_BASE_URL="$doctor_service_base_url"} \
      ${enable_kafka:+KAFKA_BOOTSTRAP_SERVERS="$KAFKA_BOOTSTRAP_SERVERS"} \
      ${enable_kafka:+APPOINTMENT_EVENTS_TOPIC="$APPOINTMENT_EVENTS_TOPIC"} \
      mvn -DskipTests spring-boot:run \
      >"$LOG_DIR/${name}.log" 2>&1 &
    echo $! > "$PID_DIR/${name}.pid"
  )
}

start_frontend() {
  (
    cd "$ROOT_DIR/frontend"
    if [ ! -d node_modules ]; then
      npm ci >/dev/null
    fi
    nohup npm run dev -- --host 127.0.0.1 --port 5173 >"$LOG_DIR/frontend.log" 2>&1 &
    echo $! > "$PID_DIR/frontend.pid"
  )
}

start_postgres_if_needed() {
  if port_open 5432; then
    echo "Using existing PostgreSQL on port 5432"
    return 0
  fi

  if ! has_cmd docker; then
    echo "PostgreSQL not available on 5432 and docker is missing"
    exit 1
  fi

  if ! docker_ready; then
    echo "PostgreSQL not available on 5432 but the Docker daemon is not running; start Docker/Colima and retry"
    exit 1
  fi

  echo "PostgreSQL not found on 5432, starting Docker image $POSTGRES_DOCKER_IMAGE"
  docker rm -f "$POSTGRES_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
  docker pull "$POSTGRES_DOCKER_IMAGE" >/dev/null
  docker run -d \
    --name "$POSTGRES_DOCKER_CONTAINER_NAME" \
    -e POSTGRES_USER="$DB_USERNAME" \
    -e POSTGRES_PASSWORD="$DB_PASSWORD" \
    -e POSTGRES_DB=healthcare_auth \
    -p 5432:5432 \
    -v "$POSTGRES_DOCKER_VOLUME:/var/lib/postgresql/data" \
    "$POSTGRES_DOCKER_IMAGE" >/dev/null

  wait_port 5432 postgres
  create_databases_in_container "$POSTGRES_DOCKER_CONTAINER_NAME"
}

start_kafka_if_needed() {
  if port_open 9092; then
    echo "Using existing Kafka on port 9092"
    return 0
  fi

  if ! has_cmd docker; then
    echo "Kafka not available on 9092 and docker is missing"
    exit 1
  fi

  if ! docker_ready; then
    echo "Kafka not available on 9092 but the Docker daemon is not running; start Docker/Colima and retry"
    exit 1
  fi

  echo "Kafka not found on 9092, starting Docker image $KAFKA_DOCKER_IMAGE"
  docker rm -f "$KAFKA_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
  docker pull "$KAFKA_DOCKER_IMAGE" >/dev/null
  if [[ "$KAFKA_DOCKER_IMAGE" == apache/kafka* ]]; then
    docker run -d \
      --name "$KAFKA_DOCKER_CONTAINER_NAME" \
      -p 9092:9092 \
      -e KAFKA_NODE_ID=1 \
      -e KAFKA_PROCESS_ROLES=broker,controller \
      -e KAFKA_CONTROLLER_QUORUM_VOTERS=1@localhost:9093 \
      -e KAFKA_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 \
      -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
      -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT \
      -e KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER \
      -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=true \
      -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
      -e KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 \
      -e KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 \
      -e CLUSTER_ID=MkU3OEVBNTcwNTJENDM2Qk \
      "$KAFKA_DOCKER_IMAGE" >/dev/null
  else
    docker run -d \
      --name "$KAFKA_DOCKER_CONTAINER_NAME" \
      -p 9092:9092 \
      -e KAFKA_CFG_NODE_ID=0 \
      -e KAFKA_CFG_PROCESS_ROLES=controller,broker \
      -e KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@localhost:9093 \
      -e KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 \
      -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
      -e KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT \
      -e KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER \
      -e KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE=true \
      -e KAFKA_CFG_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
      -e KAFKA_CFG_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 \
      -e KAFKA_CFG_TRANSACTION_STATE_LOG_MIN_ISR=1 \
      -e KAFKA_KRAFT_CLUSTER_ID=MkU3OEVBNTcwNTJENDM2Qk \
      -v "$KAFKA_DOCKER_VOLUME:/bitnami/kafka" \
      "$KAFKA_DOCKER_IMAGE" >/dev/null
  fi

  wait_port 9092 kafka
}

start_nginx_gateway() {
  if has_cmd nginx; then
    echo "Starting local nginx binary"
    nginx -p "$NGINX_PREFIX" -c "$ROOT_DIR/gateway/nginx.local.conf"
    return 0
  fi

  if ! has_cmd docker; then
    echo "Missing required command: nginx or docker"
    exit 1
  fi

  if ! docker_ready; then
    echo "Docker is installed but the daemon is not running; start Docker/Colima and retry"
    exit 1
  fi

  echo "nginx not found, starting gateway with Docker image $NGINX_DOCKER_IMAGE"
  docker rm -f "$NGINX_DOCKER_CONTAINER_NAME" >/dev/null 2>&1 || true
  docker pull "$NGINX_DOCKER_IMAGE" >/dev/null
  docker run -d \
    --name "$NGINX_DOCKER_CONTAINER_NAME" \
    -p 8080:8080 \
    -v "$ROOT_DIR/gateway/nginx.local.conf:/etc/nginx/nginx.conf:ro" \
    "$NGINX_DOCKER_IMAGE" >/dev/null
}

require_cmd mvn
require_cmd npm
require_cmd nc
resolve_java_home

stop_existing
start_postgres_if_needed
start_kafka_if_needed
create_databases_if_possible

start_service auth-service backend/auth-service 8081 healthcare_auth "$JWT_SECRET_AUTH"
start_service hospital-service backend/hospital-service 8082 healthcare_hospital "$JWT_SECRET_SERVICES"
start_service patient-service backend/patient-service 8083 healthcare_patient "$JWT_SECRET_SERVICES" "http://localhost:8084"
start_service doctor-service backend/doctor-service 8084 healthcare_doctor "$JWT_SECRET_SERVICES" "http://localhost:8083"
start_service appointment-service backend/appointment-service 8085 healthcare_appointment "$JWT_SECRET_SERVICES" "http://localhost:8083" "http://localhost:8084" true
start_service notification-service backend/notification-service 8086 healthcare_notification "$JWT_SECRET_SERVICES" "" "" true
start_frontend

wait_port 8081 auth-service
wait_port 8082 hospital-service
wait_port 8083 patient-service
wait_port 8084 doctor-service
wait_port 8085 appointment-service
wait_port 8086 notification-service
wait_port 9092 kafka
wait_port 5173 frontend

start_nginx_gateway
wait_port 8080 gateway

echo ""
echo "Local stack started without Docker:"
echo "- Gateway:   http://localhost:8080"
echo "- Frontend:  http://localhost:5173 (dev server)"
echo "- Logs:      $LOG_DIR"
