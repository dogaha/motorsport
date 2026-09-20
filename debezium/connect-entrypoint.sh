#!/bin/bash
set -euo pipefail

SECRET_NAME="${CONFLUENT_SECRET_NAME:-motorsport-confluent-connect}"
AWS_REGION="${AWS_REGION:-us-east-2}"

SECRET=""
for attempt in 1 2 3 4 5 6; do
  if SECRET=$(aws secretsmanager get-secret-value \
      --secret-id "$SECRET_NAME" --region "$AWS_REGION" \
      --query SecretString --output text); then
    break
  fi
  echo "confluent secret fetch failed (attempt $attempt), retrying..." >&2
  sleep 5
done
[ -n "$SECRET" ] || { echo "could not fetch confluent secret" >&2; exit 1; }

KEY=$(echo "$SECRET" | jq -r .api_key)
PASS=$(echo "$SECRET" | jq -r .api_secret)
JAAS="org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${KEY}\" password=\"${PASS}\";"

export CONNECT_BOOTSTRAP_SERVERS="$(echo "$SECRET" | jq -r .bootstrap)"
export CONNECT_SASL_JAAS_CONFIG="$JAAS"
export CONNECT_PRODUCER_SASL_JAAS_CONFIG="$JAAS"
export CONNECT_CONSUMER_SASL_JAAS_CONFIG="$JAAS"
export CONNECT_ADMIN_SASL_JAAS_CONFIG="$JAAS"

exec /etc/confluent/docker/run