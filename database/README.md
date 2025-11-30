# Database Module

## Overview

This module provisions an RDS PostgreSQL instance configured for Change Data Capture (CDC) with Debezium. It includes KMS encryption, Secrets Manager integration, and CDC-optimized parameter groups.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Database Module                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    RDS PostgreSQL                         │   │
│  │  ┌─────────────────────────────────────────────────────┐ │   │
│  │  │  - Engine: PostgreSQL 14.x                          │ │   │
│  │  │  - CDC Enabled (wal_level = logical)                │ │   │
│  │  │  - Multi-AZ Support                                 │ │   │
│  │  │  - Storage Autoscaling                              │ │   │
│  │  └─────────────────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│         ┌────────────────────┼────────────────────┐             │
│         │                    │                    │             │
│         ▼                    ▼                    ▼             │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │   KMS Key   │     │  Security   │     │  Secrets    │       │
│  │ (Encryption)│     │   Group     │     │  Manager    │       │
│  └─────────────┘     └─────────────┘     └─────────────┘       │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              DB Parameter Group (CDC Enabled)             │   │
│  │  - rds.logical_replication = 1                           │   │
│  │  - wal_level = logical                                   │   │
│  │  - max_replication_slots = 10                            │   │
│  │  - max_wal_senders = 10                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Features

- **CDC-Ready Configuration**: Pre-configured for logical replication with Debezium
- **KMS Encryption**: Customer-managed key for data at rest encryption
- **Secrets Manager**: Automatic credential rotation support
- **Storage Autoscaling**: Automatic storage expansion
- **Automated Backups**: Configurable retention period
- **Performance Insights**: Optional monitoring enabled

## Usage

```hcl
module "database" {
  source = "git::https://github.com/your-org/kraken-demo-module.git//database?ref=v1.0.0"

  app_name    = "kraken-demo"
  env         = "dev"
  region      = "us-east-1"
  account_id  = "123456789012"
  common_tags = var.common_tags

  # Network
  vpc_id                = data.aws_vpc.selected.id
  db_subnet_ids         = data.aws_subnets.private.ids
  allowed_ingress_cidrs = [data.aws_vpc.selected.cidr_block]

  # Database Configuration
  db_name           = "kraken_db"
  db_engine_version = "14.7"
  db_instance_class = "db.t3.medium"

  db_allocated_storage     = 20
  db_max_allocated_storage = 100
  db_storage_type          = "gp3"

  db_username = "postgres"
  db_multi_az = false

  # Backup & Maintenance
  backup_retention_period = 7
  skip_final_snapshot     = true   # Set to false in production
  deletion_protection     = false  # Set to true in production
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `app_name` | Application name | `string` | n/a | yes |
| `env` | Environment | `string` | n/a | yes |
| `region` | AWS region | `string` | n/a | yes |
| `account_id` | AWS account ID | `string` | n/a | yes |
| `common_tags` | Common tags | `map(string)` | `{}` | no |
| `vpc_id` | VPC ID | `string` | n/a | yes |
| `db_subnet_ids` | Subnet IDs for DB subnet group | `list(string)` | n/a | yes |
| `allowed_ingress_cidrs` | CIDRs allowed to access DB | `list(string)` | `[]` | no |
| `allowed_ingress_security_groups` | Security groups allowed to access DB | `list(string)` | `[]` | no |
| `db_name` | Database name | `string` | `"kraken_db"` | no |
| `db_engine_version` | PostgreSQL version | `string` | `"14.7"` | no |
| `db_instance_class` | Instance type | `string` | `"db.t3.medium"` | no |
| `db_allocated_storage` | Initial storage (GB) | `number` | `20` | no |
| `db_max_allocated_storage` | Max storage for autoscaling | `number` | `100` | no |
| `db_storage_type` | Storage type | `string` | `"gp3"` | no |
| `db_multi_az` | Enable Multi-AZ | `bool` | `false` | no |
| `db_username` | Master username | `string` | `"postgres"` | no |
| `backup_retention_period` | Backup retention days | `number` | `7` | no |
| `skip_final_snapshot` | Skip final snapshot on delete | `bool` | `true` | no |
| `deletion_protection` | Enable deletion protection | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `kms_key_arn` | KMS key ARN for DB encryption |
| `endpoint` | DB connection endpoint (host:port) |
| `address` | DB hostname |
| `port` | DB port |
| `db_name` | Database name |
| `db_instance_id` | RDS instance ID |
| `db_resource_id` | RDS resource ID (for DMS) |
| `db_arn` | RDS instance ARN |
| `security_group_id` | Security group ID |
| `master_secret_arn` | Secrets Manager secret ARN |
| `master_secret_name` | Secrets Manager secret name |
| `parameter_group_name` | Parameter group name |
| `engine` | Database engine |
| `engine_version` | Database engine version |

## CDC Configuration

This module configures PostgreSQL for logical replication required by Debezium:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `rds.logical_replication` | 1 | Enable logical replication |
| `wal_level` | logical | Required for CDC |
| `max_replication_slots` | 10 | Max concurrent CDC connectors |
| `max_wal_senders` | 10 | Max concurrent WAL senders |

## Security Considerations

1. **Encryption**: All data encrypted with customer-managed KMS key
2. **Credentials**: Master password stored in Secrets Manager
3. **Network**: Security group restricts access to specified CIDRs/security groups
4. **No Public Access**: Instance deployed in private subnets only

## Secrets Manager Secret Format

The master credentials secret contains:
```json
{
  "username": "postgres",
  "password": "auto-generated",
  "engine": "postgres",
  "host": "kraken-demo-dev.xxxxxxx.us-east-1.rds.amazonaws.com",
  "port": 5432,
  "dbname": "kraken_db"
}
```

## Production Recommendations

For production deployments, consider:

1. **Enable Multi-AZ**: Set `db_multi_az = true`
2. **Enable Deletion Protection**: Set `deletion_protection = true`
3. **Disable Skip Final Snapshot**: Set `skip_final_snapshot = false`
4. **Larger Instance**: Use `db.r6g.large` or larger
5. **Longer Backup Retention**: Set `backup_retention_period = 30`
6. **Enable Performance Insights**: Add performance insights configuration

## Dependencies

- AWS Provider >= 5.0
- Existing VPC with private subnets
- Subnets in at least 2 AZs (required for DB subnet group)

## Related Modules

- [msk-connect](../msk-connect) - Debezium connector uses this database as source
- [storage](../storage) - Data ultimately lands in S3 via MSK Connect
