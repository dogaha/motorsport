#!/bin/bash
set -euo pipefail

BOOTSTRAP="kafka:9092"
KT="/opt/kafka/bin/kafka-topics.sh"

create_topic() {
  local name="$1" partitions="$2"
  "$KT" --create --if-not-exists \
    --bootstrap-server "$BOOTSTRAP" \
    --topic "$name" \
    --partitions "$partitions" \
    --replication-factor 1 \
    --config cleanup.policy=compact
  echo "topic ready: $name"
}

create_topic connect-configs 1
create_topic connect-offsets 25
create_topic connect-status 5