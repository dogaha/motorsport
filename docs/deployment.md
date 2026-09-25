# Running this yourself

Prereqs: AWS account, Confluent Cloud API key + secret, Databricks account
(paid workspace, not Free Edition).

## 1. Create the Terraform IAM user

```bash
aws iam create-user --user-name motorsport-terraform
aws iam put-user-policy \
  --user-name motorsport-terraform \
  --policy-name motorsport-terraform-policy \
  --policy-document file://docs/motorsport-terraform-policy.json
aws iam create-access-key --user-name motorsport-terraform
# copy the AccessKeyId/SecretAccessKey into your AWS CLI profile / env vars
```

## 2. Bootstrap (Terraform state backend)

```bash
cd infra/bootstrap
terraform init
terraform apply
```

## 3. Export Confluent credentials

```bash
export CONFLUENT_CLOUD_API_KEY="<your-confluent-key>"
export CONFLUENT_CLOUD_API_SECRET="<your-confluent-secret>"
```

## 4. Run Confluent (cluster, service accounts, per-client keys)

```bash
cd ../confluent
terraform init
terraform apply
```

## 5. Push Confluent-generated credentials into AWS Secrets Manager

```bash
BOOT=$(terraform output -raw bootstrap_endpoint | sed 's#^SASL_SSL://##')

aws secretsmanager create-secret --region us-east-2 \
  --name motorsport-confluent-producer \
  --secret-string "$(jq -n --arg b "$BOOT" \
    --arg k "$(terraform output -raw producer_api_key)" \
    --arg s "$(terraform output -raw producer_api_secret)" \
    '{bootstrap:$b, api_key:$k, api_secret:$s}')"

aws secretsmanager create-secret --region us-east-2 \
  --name motorsport-confluent-connect \
  --secret-string "$(jq -n --arg b "$BOOT" \
    --arg k "$(terraform output -raw connect_api_key)" \
    --arg s "$(terraform output -raw connect_api_secret)" \
    '{bootstrap:$b, api_key:$k, api_secret:$s}')"

aws secretsmanager create-secret --region us-east-2 \
  --name motorsport-confluent-databricks \
  --secret-string "$(jq -n --arg b "$BOOT" \
    --arg k "$(terraform output -raw databricks_api_key)" \
    --arg s "$(terraform output -raw databricks_api_secret)" \
    '{bootstrap:$b, api_key:$k, api_secret:$s}')"
```

## 6. Set up the Databricks CLI and workspace

```bash
databricks configure --host <your-workspace-url>
# paste personal access token when prompted
```

After setting up the workspace, execute the `src/pipline/connection-checks.ipynb` 
within Databricks.
## 7. Push Confluent credentials into Databricks secrets

```bash
aws secretsmanager get-secret-value --secret-id motorsport-confluent-databricks \
  --query SecretString --output text | jq -r '.bootstrap' | tr -d '\r\n' \
  | databricks secrets put-secret motorsport kafka_bootstrap

aws secretsmanager get-secret-value --secret-id motorsport-confluent-databricks \
  --query SecretString --output text | jq -r '.api_key' | tr -d '\r\n' \
  | databricks secrets put-secret motorsport kafka_api_key

aws secretsmanager get-secret-value --secret-id motorsport-confluent-databricks \
  --query SecretString --output text | jq -r '.api_secret' | tr -d '\r\n' \
  | databricks secrets put-secret motorsport kafka_api_secret
```

## 8. Run AWS (networking, EC2, RDS, S3, IAM roles including Unity Catalog role)

```bash
cd ../aws
terraform init
terraform apply
```

If this is the *first* apply and the Databricks UC role's trust policy
needs the external ID added, apply once with the master-role-only trust
policy, then update `terraform.tfvars` with
`databricks_uc_external_id`/`databricks_uc_master_role_arn` and re-apply:

```bash
terraform apply   # first pass: principal only
# add databricks_uc_master_role_arn / databricks_uc_external_id to tfvars
terraform apply   # second pass: adds self-ARN
```

This step creates and boots EC2, which will run `docker compose up -d
--build` automatically via `user_data`. Because Confluent and Databricks
secrets already exist (steps 4-7 ran first), Kafka Connect should come up
correctly on first boot.

## 9. Load the Databricks Job

Go to the web UI and create a job using the `docs/databricks_jobs.yml` file

Enable the Job's schedule (UI: Workflows → Jobs → your job → Schedule →
toggle on). The pipeline will not run until this is turned on.

## 10. Seed the dbt sensors table

```bash
cd ../../dbt
dbt deps
dbt seed
```

## 11. SSH into EC2 and verify the stack

```bash
ssh -i ~/.ssh/motorsport-ec2 ec2-user@<ec2-public-ip>
cd /opt/motorsport
docker compose ps
# Connect should be Up; init-connector should have exited 0
```

## Create the generators
```
docker run -d --name generator-metadata --restart on-failure \
  -e PYTHONUNBUFFERED=1 \
  motorsport-app python -m src.generators.metadata

docker run -d --name generator-telemetry --restart on-failure \
  -e PYTHONUNBUFFERED=1 \
  motorsport-app python -m src.generators.telemetry
```

## 13. Start the generators

```bash
docker start generator-telemetry generator-metadata

# For watching logs
docker compose logs -f generator-telemetry   # Ctrl+C to stop watching, containers keep running
docker compose logs -f generator-metadata   # Ctrl+C to stop watching, containers keep running
```

## Stopping / teardown (in this order)

```bash
# 1. Pause the Databricks Job schedule (UI)

# 2. Stop the generators
docker compose stop generator-telemetry generator-metadata

# 3. Destroy AWS
cd infra/aws && terraform destroy

# 4. Destroy Confluent
cd ../confluent && terraform destroy

# Keep: infra/bootstrap (state bucket), and optionally the
# motorsport-data-lake S3 bucket if you want to keep the data.
```