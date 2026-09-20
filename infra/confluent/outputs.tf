# ---------------------------------------------------------------------------
# Outputs: non-secret IDs plus per-client key material (all sensitive)
# ---------------------------------------------------------------------------
output "environment_id" {
  value = confluent_environment.motorsport.id
}

output "cluster_id" {
  value = confluent_kafka_cluster.standard.id
}

output "bootstrap_endpoint" {
  value = confluent_kafka_cluster.standard.bootstrap_endpoint
}

output "producer_api_key" {
  value     = confluent_api_key.producer.id
  sensitive = true
}

output "producer_api_secret" {
  value     = confluent_api_key.producer.secret
  sensitive = true
}

output "connect_api_key" {
  value     = confluent_api_key.connect.id
  sensitive = true
}

output "connect_api_secret" {
  value     = confluent_api_key.connect.secret
  sensitive = true
}

output "databricks_api_key" {
  value     = confluent_api_key.databricks.id
  sensitive = true
}

output "databricks_api_secret" {
  value     = confluent_api_key.databricks.secret
  sensitive = true
}