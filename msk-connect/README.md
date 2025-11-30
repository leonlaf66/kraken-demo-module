# MSK Connect Module

## Overview

This module provisions MSK Connect connectors with least-privilege IAM policies, supporting both source (Debezium CDC) and sink (S3) connector types.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           MSK Connect Module                              │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                      MSK Connect Connector                          │ │
│  │  ┌───────────────────────────────────────────────────────────────┐ │ │
│  │  │  Capacity: Autoscaling (1-10 workers, 1-8 MCU)               │ │ │
│  │  │  Plugin: Custom (Debezium/Confluent S3)                      │ │ │
│  │  │  Logging: CloudWatch Logs                                     │ │ │
│  │  └───────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                               │                                           │
│              ┌────────────────┼────────────────┐                         │
│              │                │                │                         │
│              ▼                ▼                ▼                         │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐                │
│  │  IAM Role     │  │  Security     │  │  CloudWatch   │                │
│  │  (Connector)  │  │  Group        │  │  Log Group    │                │
│  └───────────────┘  └───────────────┘  └───────────────┘                │
│         │                                                                │
│         ▼                                                                │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │                    IAM Policy (Least Privilege)                     ││
│  │  - MSK Cluster Access                                               ││
│  │  - Topic-specific Read/Write (based on connector type)              ││
│  │  - S3 Bucket Access (for sink connectors)                           ││
│  │  - KMS Decrypt (for encrypted resources)                            ││
│  │  - Secrets Manager Read (for RDS credentials)                       ││
│  │  - CloudWatch Logs Write                                            ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Autoscaling**: Automatic worker scaling based on CPU utilization
- **Least Privilege IAM**: Topic-level permissions based on connector type
- **Flexible Authentication**: Supports IAM and NONE (for NLB/SCRAM setups)
- **CloudWatch Logging**: Centralized connector logs
- **Custom Plugins**: Support for Debezium and Confluent S3 Sink

## Usage

### Debezium CDC Source Connector

```hcl
module "debezium_cdc_source" {
  source = "git::https://github.com/your-org/kraken-demo-module.git//msk-connect?ref=v1.0.0"

  connector_name       = "debezium-postgres-cdc-dev"
  env                  = "dev"
  region               = "us-east-1"
  account_id           = "123456789012"
  connector_type       = "source"
  kafkaconnect_version = "2.7.1"

  # Network
  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  # MSK
  msk_cluster_arn         = var.msk_cluster_arn
  msk_bootstrap_servers   = var.msk_bootstrap_brokers_nlb
  msk_authentication_type = "NONE"  # Using NLB with SCRAM at broker level
  msk_kms_key_arn         = var.msk_kms_key_arn

  # Permissions
  kafka_topics_write = ["cdc.trades.mnpi", "cdc.orders.mnpi", "cdc.positions.mnpi"]
  kafka_topics_read  = []

  # RDS Access
  rds_secret_arn = data.aws_secretsmanager_secret.database.arn

  # Plugin
  custom_plugin_arn        = var.debezium_plugin_arn
  custom_plugin_revision   = 1
  custom_plugin_bucket_arn = var.plugin_bucket_arn

  # No S3 for source
  s3_sink_bucket_arn = null
  s3_kms_key_arn     = null

  # Connector Configuration
  connector_configuration = {
    "connector.class"          = "io.debezium.connector.postgresql.PostgresConnector"
    "database.hostname"        = local.database_creds.host
    "database.port"            = "5432"
    "database.user"            = local.database_creds.username
    "database.password"        = local.database_creds.password
    "database.dbname"          = local.database_creds.dbname
    "database.server.name"     = "kraken-cdc"
    "plugin.name"              = "pgoutput"
    "slot.name"                = "debezium_cdc_slot"
    "table.include.list"       = "public.trades,public.orders,public.positions"
    "key.converter"            = "org.apache.kafka.connect.json.JsonConverter"
    "value.converter"          = "org.apache.kafka.connect.json.JsonConverter"
    "tasks.max"                = "1"
  }

  # Autoscaling
  autoscaling_mcu_count        = 1
  autoscaling_min_worker_count = 1
  autoscaling_max_worker_count = 2

  common_tags = var.common_tags
}
```

### S3 Sink Connector

```hcl
module "s3_sink_mnpi" {
  source = "git::https://github.com/your-org/kraken-demo-module.git//msk-connect?ref=v1.0.0"

  connector_name       = "s3-sink-raw-mnpi-dev"
  env                  = "dev"
  region               = "us-east-1"
  account_id           = "123456789012"
  connector_type       = "sink"
  kafkaconnect_version = "2.7.1"

  # Network
  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  # MSK
  msk_cluster_arn         = var.msk_cluster_arn
  msk_bootstrap_servers   = var.msk_bootstrap_brokers_nlb
  msk_authentication_type = "NONE"
  msk_kms_key_arn         = var.msk_kms_key_arn

  # Permissions (Read from topics, no write)
  kafka_topics_write = []
  kafka_topics_read  = ["cdc.trades.mnpi", "cdc.orders.mnpi", "cdc.positions.mnpi"]

  # No RDS access needed
  rds_secret_arn = null

  # Plugin
  custom_plugin_arn        = var.s3_sink_plugin_arn
  custom_plugin_revision   = 1
  custom_plugin_bucket_arn = var.plugin_bucket_arn

  # S3 Destination
  s3_sink_bucket_arn = var.bucket_raw_mnpi_arn
  s3_kms_key_arn     = var.kms_key_mnpi_arn

  # Connector Configuration
  connector_configuration = {
    "connector.class"         = "io.confluent.connect.s3.S3SinkConnector"
    "topics"                  = "cdc.trades.mnpi,cdc.orders.mnpi,cdc.positions.mnpi"
    "s3.bucket.name"          = var.bucket_raw_mnpi_id
    "s3.region"               = "us-east-1"
    "storage.class"           = "io.confluent.connect.s3.storage.S3Storage"
    "format.class"            = "io.confluent.connect.s3.format.json.JsonFormat"
    "partitioner.class"       = "io.confluent.connect.storage.partitioner.TimeBasedPartitioner"
    "path.format"             = "'year'=YYYY/'month'=MM/'day'=dd/'hour'=HH"
    "partition.duration.ms"   = "3600000"
    "flush.size"              = "1000"
    "tasks.max"               = "3"
  }

  # Autoscaling
  autoscaling_mcu_count        = 1
  autoscaling_min_worker_count = 1
  autoscaling_max_worker_count = 4

  common_tags = var.common_tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `connector_name` | Connector name | `string` | n/a | yes |
| `env` | Environment | `string` | n/a | yes |
| `region` | AWS region | `string` | n/a | yes |
| `account_id` | AWS account ID | `string` | n/a | yes |
| `connector_type` | `"source"` or `"sink"` | `string` | n/a | yes |
| `kafkaconnect_version` | Kafka Connect version | `string` | `"2.7.1"` | no |
| `vpc_id` | VPC ID | `string` | n/a | yes |
| `subnet_ids` | Subnet IDs | `list(string)` | n/a | yes |
| `msk_cluster_arn` | MSK cluster ARN | `string` | n/a | yes |
| `msk_bootstrap_servers` | Bootstrap servers | `string` | n/a | yes |
| `msk_authentication_type` | `"IAM"` or `"NONE"` | `string` | `"IAM"` | no |
| `msk_kms_key_arn` | MSK KMS key ARN | `string` | `null` | no |
| `kafka_topics_read` | Topics to read | `list(string)` | `[]` | no |
| `kafka_topics_write` | Topics to write | `list(string)` | `[]` | no |
| `rds_secret_arn` | RDS credentials secret ARN | `string` | `null` | no |
| `s3_sink_bucket_arn` | S3 bucket ARN (for sink) | `string` | `null` | no |
| `s3_kms_key_arn` | S3 KMS key ARN | `string` | `null` | no |
| `custom_plugin_arn` | Plugin ARN | `string` | n/a | yes |
| `custom_plugin_revision` | Plugin revision | `number` | `1` | no |
| `custom_plugin_bucket_arn` | Plugin S3 bucket ARN | `string` | n/a | yes |
| `connector_configuration` | Connector config map | `map(string)` | n/a | yes |
| `autoscaling_mcu_count` | MCU per worker (1,2,4,8) | `number` | `1` | no |
| `autoscaling_min_worker_count` | Min workers | `number` | `1` | no |
| `autoscaling_max_worker_count` | Max workers | `number` | `2` | no |
| `autoscaling_scale_in_cpu` | Scale in CPU % | `number` | `20` | no |
| `autoscaling_scale_out_cpu` | Scale out CPU % | `number` | `80` | no |
| `log_retention_in_days` | Log retention | `number` | `7` | no |
| `common_tags` | Common tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `connector_arn` | Connector ARN |
| `connector_version` | Connector version |
| `security_group_id` | Security group ID |
| `iam_role_arn` | IAM role ARN |

## IAM Permissions by Connector Type

### Source Connector (Debezium)
- MSK: Connect to cluster
- Kafka: Write to specified topics, Create topics
- Secrets Manager: Read RDS credentials
- KMS: Decrypt MSK data

### Sink Connector (S3)
- MSK: Connect to cluster
- Kafka: Read from specified topics
- S3: PutObject to destination bucket
- KMS: Encrypt/Decrypt S3 data

## Autoscaling Configuration

| Setting | Min | Max | Recommendation |
|---------|-----|-----|----------------|
| MCU Count | 1 | 8 | Start with 1, increase for throughput |
| Workers | 1 | 10 | Scale based on partition count |
| Scale Out CPU | 1% | 100% | 80% is good default |
| Scale In CPU | 1% | 100% | 20% is good default |

## Authentication Types

| Type | When to Use | Notes |
|------|-------------|-------|
| `IAM` | Direct MSK access | Best for AWS-native integration |
| `NONE` | Via NLB/SCRAM | Required when using NLB endpoint |

**Important**: When using `NONE`, authentication happens at the Kafka protocol level (SCRAM configured in connector properties), not at the MSK Connect level.

## Security Considerations

1. **Least Privilege**: IAM policies grant only required topic access
2. **Network Isolation**: Connector runs in private subnets
3. **Encryption**: TLS in transit, KMS at rest
4. **Credential Management**: Use Secrets Manager for database credentials

## Troubleshooting

### Connector Not Starting
1. Check CloudWatch Logs: `/aws/msk-connect/{connector-name}`
2. Verify security group allows outbound to MSK
3. Confirm IAM role has required permissions

### Connection Failures
1. Verify bootstrap servers are reachable
2. Check authentication type matches MSK configuration
3. Validate VPC connectivity

## Dependencies

- AWS Provider >= 5.0
- Existing MSK cluster
- Custom plugin uploaded to S3
- VPC with private subnets

## Related Modules

- [msk](../msk) - MSK cluster this connects to
- [database](../database) - Source database for CDC
- [storage](../storage) - Destination buckets for S3 sink
- [kafka-data-plane](../kafka-data-plane) - Topic and ACL management
