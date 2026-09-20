terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.86.0"
    }
  }
}

# Auth via env: CONFLUENT_CLOUD_API_KEY and CONFLUENT_CLOUD_API_SECRET
provider "confluent" {}

# ---------------------------------------------------------------------------
# Environment and cluster
# ---------------------------------------------------------------------------
resource "confluent_environment" "motorsport" {
  display_name = "motorsport"
}

resource "confluent_kafka_cluster" "standard" {
  display_name = "motorsport-kafka"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-2"
  standard {}

  environment {
    id = confluent_environment.motorsport.id
  }
}

# ---------------------------------------------------------------------------
# Service accounts
# ---------------------------------------------------------------------------
resource "confluent_service_account" "terraform" {
  display_name = "motorsport-terraform"
  description  = "Manages topics on the motorsport cluster"
}

resource "confluent_service_account" "producer" {
  display_name = "motorsport-producer"
  description  = "Telemetry generator: writes to the telemetry topic"
}

resource "confluent_service_account" "connect" {
  display_name = "motorsport-connect"
  description  = "Kafka Connect / Debezium: writes CDC topics, uses Connect internal topics"
}

resource "confluent_service_account" "databricks" {
  display_name = "motorsport-databricks"
  description  = "Databricks Structured Streaming: read-only on data topics"
}

# ---------------------------------------------------------------------------
# Admin identity used only by Terraform to create topics
# ---------------------------------------------------------------------------
resource "confluent_role_binding" "terraform_cluster_admin" {
  principal   = "User:${confluent_service_account.terraform.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.standard.rbac_crn
}

resource "confluent_api_key" "terraform" {
  display_name = "motorsport-terraform-kafka-api-key"
  description  = "Kafka API key owned by motorsport-terraform"

  owner {
    id          = confluent_service_account.terraform.id
    api_version = confluent_service_account.terraform.api_version
    kind        = confluent_service_account.terraform.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.motorsport.id
    }
  }

  # Role must exist before this key is used to create topics
  depends_on = [confluent_role_binding.terraform_cluster_admin]
}

# ---------------------------------------------------------------------------
# Topics
# ---------------------------------------------------------------------------
locals {
  # Connect internal topics: compacted, sizes from Connect's recommended defaults
  connect_topics = {
    "connect-configs" = 1
    "connect-offsets" = 25
    "connect-status"  = 5
  }

  # Debezium CDC topics: <topic.prefix>.<schema>.<table>
  cdc_topics = [
    "motorsport.public.tracks",
    "motorsport.public.track_sections",
    "motorsport.public.drivers",
    "motorsport.public.vehicles",
    "motorsport.public.sessions",
    "motorsport.public.sensors",
  ]

  data_topics = concat(local.cdc_topics, ["telemetry"])
}

resource "confluent_kafka_topic" "connect" {
  for_each = local.connect_topics

  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name       = each.key
  partitions_count = each.value
  rest_endpoint    = confluent_kafka_cluster.standard.rest_endpoint

  config = {
    "cleanup.policy" = "compact"
  }

  credentials {
    key    = confluent_api_key.terraform.id
    secret = confluent_api_key.terraform.secret
  }
}

resource "confluent_kafka_topic" "data" {
  for_each = toset(local.data_topics)

  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name       = each.value
  partitions_count = 1
  rest_endpoint    = confluent_kafka_cluster.standard.rest_endpoint

  credentials {
    key    = confluent_api_key.terraform.id
    secret = confluent_api_key.terraform.secret
  }
}

# ---------------------------------------------------------------------------
# Producer: write to telemetry
# ---------------------------------------------------------------------------
resource "confluent_api_key" "producer" {
  display_name = "motorsport-producer-kafka-api-key"
  description  = "Kafka API key owned by motorsport-producer"

  owner {
    id          = confluent_service_account.producer.id
    api_version = confluent_service_account.producer.api_version
    kind        = confluent_service_account.producer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.motorsport.id
    }
  }
}

resource "confluent_role_binding" "producer_write_telemetry" {
  principal   = "User:${confluent_service_account.producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=telemetry"

  depends_on = [confluent_kafka_topic.data]
}

# ---------------------------------------------------------------------------
# Connect: write CDC topics, read/write its internal topics
# ---------------------------------------------------------------------------
resource "confluent_api_key" "connect" {
  display_name = "motorsport-connect-kafka-api-key"
  description  = "Kafka API key owned by motorsport-connect"

  owner {
    id          = confluent_service_account.connect.id
    api_version = confluent_service_account.connect.api_version
    kind        = confluent_service_account.connect.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.motorsport.id
    }
  }
}

resource "confluent_role_binding" "connect_write_cdc" {
  for_each = toset(local.cdc_topics)

  principal   = "User:${confluent_service_account.connect.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${each.value}"

  depends_on = [confluent_kafka_topic.data]
}

resource "confluent_role_binding" "connect_internal_write" {
  for_each = local.connect_topics

  principal   = "User:${confluent_service_account.connect.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${each.key}"

  depends_on = [confluent_kafka_topic.connect]
}

resource "confluent_role_binding" "connect_internal_read" {
  for_each = local.connect_topics

  principal   = "User:${confluent_service_account.connect.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${each.key}"

  depends_on = [confluent_kafka_topic.connect]
}

# Connect worker group (default group.id used by the distributed worker)
resource "confluent_role_binding" "connect_group_read" {
  principal   = "User:${confluent_service_account.connect.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/group=motorsport-connect*"
}

# ---------------------------------------------------------------------------
# Databricks: read-only on data topics, consumer group with a known prefix
# ---------------------------------------------------------------------------
resource "confluent_api_key" "databricks" {
  display_name = "motorsport-databricks-kafka-api-key"
  description  = "Kafka API key owned by motorsport-databricks"

  owner {
    id          = confluent_service_account.databricks.id
    api_version = confluent_service_account.databricks.api_version
    kind        = confluent_service_account.databricks.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.motorsport.id
    }
  }
}

resource "confluent_role_binding" "databricks_read_topics" {
  for_each = toset(local.data_topics)

  principal   = "User:${confluent_service_account.databricks.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${each.value}"

  depends_on = [confluent_kafka_topic.data]
}

# Spark must set kafka.group.id to a value starting with "motorsport-databricks"
resource "confluent_role_binding" "databricks_read_group" {
  principal   = "User:${confluent_service_account.databricks.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/group=motorsport-databricks*"
}