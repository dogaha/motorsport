#!/bin/bash
set -euo pipefail

SECRET_NAME="${SECRET_NAME:-motorsport-rds-credentials}"
AWS_REGION="${AWS_REGION:-us-east-2}"
CONNECT_URL="http://kafka-connect:8083"
CONNECTOR_NAME="motorsport-connector"

# 1. Credentials from Secrets Manager (retry: instance-role creds can lag at boot)
SECRET=""
for attempt in 1 2 3 4 5 6; do
  if SECRET=$(aws secretsmanager get-secret-value \
      --secret-id "$SECRET_NAME" --region "$AWS_REGION" \
      --query SecretString --output text); then
    break
  fi
  echo "secret fetch failed (attempt $attempt), retrying..."
  sleep 5
done
[ -n "$SECRET" ] || { echo "could not fetch secret"; exit 1; }

DB_HOST=$(echo "$SECRET" | jq -r .host)
DB_PORT=$(echo "$SECRET" | jq -r '.port // 5432')
DB_NAME=$(echo "$SECRET" | jq -r .dbname)
DB_USER=$(echo "$SECRET" | jq -r .username)
DB_PASSWORD=$(echo "$SECRET" | jq -r .password)

# 2. Wait for Postgres, then apply schema (idempotent)
until PGPASSWORD="$DB_PASSWORD" pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"; do
  echo "waiting for postgres..."
  sleep 5
done

PGPASSWORD="$DB_PASSWORD" psql \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
  -v ON_ERROR_STOP=1 -f /db/init_tables.sql

# 2b. Seed only if the DB is fresh (drivers table empty)
ROW_COUNT=$(PGPASSWORD="$DB_PASSWORD" psql \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
  -tA -c "SELECT COUNT(*) FROM drivers;")

if [ "$ROW_COUNT" -eq 0 ]; then
  echo "empty database, seeding..."
  PGPASSWORD="$DB_PASSWORD" psql \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -v ON_ERROR_STOP=1 --single-transaction -f /db/seed_tables.sql
else
  echo "database already seeded, skipping"
fi

# 2c. Sensors: idempotent upsert, safe to run every start
PGPASSWORD="$DB_PASSWORD" psql \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
  -v ON_ERROR_STOP=1 -f /db/seed_sensors_table.sql

# 3. Register connector (PUT = create or update); jq escapes values safely
jq --arg host "$DB_HOST" --arg port "$DB_PORT" --arg user "$DB_USER" \
   --arg pass "$DB_PASSWORD" --arg db "$DB_NAME" \
   '.["database.hostname"]=$host
    | .["database.port"]=$port
    | .["database.user"]=$user
    | .["database.password"]=$pass
    | .["database.dbname"]=$db' \
   /debezium/connector.json \
 | curl -sS --fail-with-body -X PUT \
     -H "Content-Type: application/json" \
     --data @- \
     "$CONNECT_URL/connectors/$CONNECTOR_NAME/config" > /dev/null

echo "connector registered: $CONNECTOR_NAME"