# MSK Module

Amazon MSK cluster with SCRAM authentication, NLB endpoint, and Route53 DNS.

## Resources Created

- MSK cluster with SCRAM-SHA-512 auth
- Network Load Balancer (stable endpoint)
- KMS key for encryption
- Secrets Manager secrets (SCRAM users)
- CloudWatch log group
- Security group
- Route53 record

## Usage

```hcl
module "msk" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//msk?ref=main"

  app_name   = "kraken-demo"
  env        = "dev"
  region     = "us-east-1"
  account_id = "123456789012"

  vpc_id          = data.aws_vpc.selected.id
  vpc_cidr        = data.aws_vpc.selected.cidr_block
  private_subnets = data.aws_subnets.private.ids

  scram_users = ["admin", "debezium", "s3_sink_mnpi"]
}
```

## Why NLB?

MSK Connect requires `authentication_type = "NONE"` but still uses SCRAM via JAAS config. The NLB provides a stable endpoint that survives broker replacements.

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| app_name | string | yes | - | Application name |
| env | string | yes | - | Environment |
| vpc_id | string | yes | - | VPC ID |
| private_subnets | list(string) | yes | - | Subnet IDs |
| kafka_version | string | no | 3.5.1 | Kafka version |
| instance_type | string | no | kafka.m5.large | Broker instance type |
| number_of_broker_nodes | number | no | 3 | Number of brokers |
| scram_users | set(string) | no | ["admin"] | SCRAM usernames |
| private_hosted_zone_id | string | no | "" | Route53 zone ID |

## Outputs

| Name | Description |
|------|-------------|
| cluster_arn | MSK cluster ARN |
| bootstrap_brokers_sasl_scram | Direct SCRAM endpoint |
| bootstrap_brokers_nlb | NLB endpoint (recommended) |
| security_group_id | MSK security group ID |
| scram_secret_names | Map of user → secret name |

## SCRAM Credentials

```bash
aws secretsmanager get-secret-value \
  --secret-id AmazonMSK_kraken-demo_dev_admin \
  --query SecretString --output text | jq
```
