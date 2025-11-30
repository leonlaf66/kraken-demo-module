# MSK Connect Module

Generic MSK Connect connector with IAM role and security group.

## Resources Created

- MSK Connect connector
- IAM role with least-privilege policy
- Security group
- CloudWatch log group

## Usage

### Source Connector (Debezium)
```hcl
module "debezium" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//msk-connect?ref=main"

  connector_name = "debezium-postgres-cdc-dev"
  connector_type = "source"
  env            = "dev"
  region         = "us-east-1"
  account_id     = "123456789012"

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  msk_cluster_arn       = var.msk_cluster_arn
  msk_bootstrap_servers = var.msk_bootstrap_brokers_nlb

  kafka_topics_write = ["cdc.trades.mnpi", "cdc.orders.mnpi"]

  custom_plugin_arn        = var.debezium_plugin_arn
  custom_plugin_bucket_arn = var.plugin_bucket_arn

  connector_configuration = {
    "connector.class" = "io.debezium.connector.postgresql.PostgresConnector"
    # ... connector-specific config
  }
}
```

### Sink Connector (S3)
```hcl
module "s3_sink" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//msk-connect?ref=main"

  connector_name = "s3-sink-raw-mnpi-dev"
  connector_type = "sink"

  kafka_topics_read  = ["cdc.trades.mnpi"]
  s3_sink_bucket_arn = var.bucket_raw_mnpi_arn
  s3_kms_key_arn     = var.kms_key_mnpi_arn

  # ... other config
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| connector_name | string | yes | Connector name |
| connector_type | string | yes | "source" or "sink" |
| msk_cluster_arn | string | yes | MSK cluster ARN |
| msk_bootstrap_servers | string | yes | Bootstrap servers |
| custom_plugin_arn | string | yes | Plugin ARN |
| custom_plugin_bucket_arn | string | yes | Plugin S3 bucket ARN |
| connector_configuration | map(string) | yes | Connector config |
| kafka_topics_write | list(string) | no | Topics to write (source) |
| kafka_topics_read | list(string) | no | Topics to read (sink) |
| s3_sink_bucket_arn | string | no | S3 bucket for sink |

## Outputs

| Name | Description |
|------|-------------|
| connector_arn | Connector ARN |
| security_group_id | Connector security group ID |
| iam_role_arn | Connector IAM role ARN |
