# Database Module

PostgreSQL RDS instance with CDC-enabled parameters for Debezium integration.

## Resources Created

- RDS PostgreSQL instance (CDC-ready)
- DB parameter group with logical replication
- KMS key for encryption
- Security group
- Secrets Manager secret for credentials
- DB subnet group

## Usage

```hcl
module "database" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//database?ref=main"

  app_name   = "kraken-demo"
  env        = "dev"
  region     = "us-east-1"
  account_id = "123456789012"

  vpc_id                = data.aws_vpc.selected.id
  db_subnet_ids         = data.aws_subnets.private.ids
  allowed_ingress_cidrs = [data.aws_vpc.selected.cidr_block]
}
```

## CDC Configuration

The parameter group enables logical replication:
- `rds.logical_replication = 1`
- `wal_sender_timeout = 0`

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| app_name | string | yes | - | Application name |
| env | string | yes | - | Environment |
| region | string | yes | - | AWS region |
| account_id | string | yes | - | AWS account ID |
| vpc_id | string | yes | - | VPC ID |
| db_subnet_ids | list(string) | yes | - | Subnet IDs (min 2 AZs) |
| db_instance_class | string | no | db.t3.medium | Instance type |
| db_engine_version | string | no | 14.7 | PostgreSQL version |

## Outputs

| Name | Description |
|------|-------------|
| endpoint | Connection endpoint (host:port) |
| address | Database hostname |
| port | Database port |
| security_group_id | RDS security group ID |
| master_secret_arn | Secrets Manager secret ARN |
| db_resource_id | RDS resource ID (for DMS) |

## Credentials

Credentials are auto-generated and stored in Secrets Manager:
```bash
aws secretsmanager get-secret-value \
  --secret-id kraken-demo-rds-master-creds-dev \
  --query SecretString --output text | jq
```
