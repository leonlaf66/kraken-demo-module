# MSK Module

## Overview

This module provisions an Amazon MSK (Managed Streaming for Apache Kafka) cluster with SCRAM authentication, NLB for stable endpoints, and optional Route53 DNS integration.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              MSK Module                                   │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                        MSK Cluster                                   │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │ │
│  │  │  Broker 1   │  │  Broker 2   │  │  Broker 3   │                 │ │
│  │  │   AZ-a      │  │   AZ-b      │  │   AZ-c      │                 │ │
│  │  │  :9096      │  │  :9096      │  │  :9096      │                 │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                 │ │
│  │         │                │                │                         │ │
│  │         └────────────────┼────────────────┘                         │ │
│  │                          │                                          │ │
│  └──────────────────────────┼──────────────────────────────────────────┘ │
│                             │                                            │
│  ┌──────────────────────────┼──────────────────────────────────────────┐│
│  │           Network Load Balancer (Internal)                          ││
│  │                          │                                          ││
│  │              kafka-bootstrap.internal:9096                          ││
│  └──────────────────────────┼──────────────────────────────────────────┘│
│                             │                                            │
│  ┌──────────────────────────┼──────────────────────────────────────────┐│
│  │                    Route53 Private Zone                             ││
│  │           kafka-bootstrap.kraken-demo.internal                      ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                                                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐          │
│  │    KMS Key      │  │  Security Group │  │ Secrets Manager │          │
│  │  (Encryption)   │  │   (Port 9096)   │  │  (SCRAM Users)  │          │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘          │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

## Features

- **SCRAM-SHA-512 Authentication**: Secure username/password authentication
- **KMS Encryption**: At-rest and in-transit encryption
- **NLB Integration**: Stable bootstrap endpoint that survives broker replacements
- **Route53 DNS**: Optional friendly DNS name for bootstrap servers
- **Automatic Secrets**: SCRAM credentials stored in Secrets Manager
- **Configurable Properties**: Full control over Kafka server properties

## Usage

```hcl
module "msk" {
  source = "git::https://github.com/your-org/kraken-demo-module.git//msk?ref=v1.0.0"

  app_name    = "kraken-demo"
  env         = "dev"
  region      = "us-east-1"
  account_id  = "123456789012"
  common_tags = var.common_tags

  # Network
  vpc_id          = data.aws_vpc.selected.id
  vpc_cidr        = data.aws_vpc.selected.cidr_block
  private_subnets = data.aws_subnets.private.ids

  # Optional Route53 integration
  private_hosted_zone_id = var.private_hosted_zone_id

  # MSK Configuration
  kafka_version          = "3.5.1"
  number_of_broker_nodes = 3
  instance_type          = "kafka.m5.large"
  ebs_volume_size        = 2000
  provisioned_throughput = 250

  # Authentication
  enable_iam  = false
  scram_users = ["admin", "debezium", "s3_sink_mnpi", "s3_sink_public"]

  # Kafka Server Properties
  server_properties = {
    "auto.create.topics.enable"  = "false"
    "delete.topic.enable"        = "true"
    "default.replication.factor" = "3"
    "min.insync.replicas"        = "2"
    "num.io.threads"             = "8"
    "num.network.threads"        = "5"
    "num.partitions"             = "3"
    "num.replica.fetchers"       = "2"
    "log.retention.ms"           = "604800000"
    "log.segment.bytes"          = "1073741824"
    "compression.type"           = "producer"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `app_name` | Application name | `string` | n/a | yes |
| `env` | Environment | `string` | n/a | yes |
| `region` | AWS region | `string` | n/a | yes |
| `account_id` | AWS account ID | `string` | n/a | yes |
| `common_tags` | Common tags | `map(string)` | n/a | yes |
| `vpc_id` | VPC ID | `string` | n/a | yes |
| `vpc_cidr` | VPC CIDR block | `string` | n/a | yes |
| `private_subnets` | Private subnet IDs | `list(string)` | n/a | yes |
| `private_hosted_zone_id` | Route53 zone ID (optional) | `string` | `""` | no |
| `kafka_version` | Kafka version | `string` | `"3.5.1"` | no |
| `number_of_broker_nodes` | Number of brokers | `number` | `3` | no |
| `instance_type` | Broker instance type | `string` | `"kafka.m5.large"` | no |
| `ebs_volume_size` | EBS volume size (GB) | `number` | `1000` | no |
| `provisioned_throughput` | Provisioned throughput (MiB/s) | `number` | `null` | no |
| `enable_iam` | Enable IAM authentication | `bool` | `false` | no |
| `scram_users` | List of SCRAM users | `set(string)` | `["admin"]` | no |
| `server_properties` | Kafka server properties | `map(string)` | See defaults | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_arn` | MSK cluster ARN |
| `cluster_name` | MSK cluster name |
| `bootstrap_brokers_sasl_scram` | Bootstrap brokers (SCRAM) |
| `bootstrap_brokers_sasl_iam` | Bootstrap brokers (IAM) |
| `bootstrap_brokers_nlb` | Stable NLB endpoint |
| `nlb_dns_name` | NLB DNS name |
| `route53_dns_name` | Route53 DNS name |
| `security_group_id` | MSK security group ID |
| `kms_key_arn` | KMS key ARN |
| `scram_secret_names` | Map of SCRAM user secret names |

## SCRAM Credentials

Each SCRAM user gets a Secrets Manager secret with the format:
- Secret Name: `AmazonMSK_{app_name}_{env}_{username}`
- Secret Value:
```json
{
  "username": "admin",
  "password": "auto-generated-32-char"
}
```

To retrieve credentials:
```bash
aws secretsmanager get-secret-value \
  --secret-id AmazonMSK_kraken-demo_dev_admin \
  --query SecretString --output text | jq
```

## NLB vs Direct Broker Access

| Access Method | Endpoint | Use Case |
|---------------|----------|----------|
| NLB (Recommended) | `kafka-bootstrap.{app}.internal:9096` | Applications, MSK Connect |
| Direct SCRAM | `b-*.{cluster}.kafka.{region}.amazonaws.com:9096` | Direct broker access |

**Why NLB?**
- Stable endpoint that survives broker replacements
- Single DNS name for all brokers
- Works with MSK Connect (which requires NONE authentication type)

## Server Properties Defaults

```hcl
{
  "auto.create.topics.enable"  = "false"   # Prevent accidental topic creation
  "delete.topic.enable"        = "true"    # Allow topic deletion
  "default.replication.factor" = "3"       # HA for new topics
  "min.insync.replicas"        = "2"       # Durability guarantee
  "num.io.threads"             = "8"       # I/O threads per broker
  "num.network.threads"        = "5"       # Network threads per broker
  "num.partitions"             = "1"       # Default partitions
  "num.replica.fetchers"       = "2"       # Replica fetcher threads
  "log.retention.ms"           = "604800000" # 7 days retention
}
```

## Security Considerations

1. **Encryption at Rest**: KMS-encrypted EBS volumes
2. **Encryption in Transit**: TLS 1.2 for all connections
3. **Authentication**: SCRAM-SHA-512 required for all clients
4. **Network**: Deployed in private subnets only
5. **Security Group**: Restricts access to VPC CIDR

## Instance Type Recommendations

| Environment | Instance Type | vCPUs | Memory | Network |
|-------------|--------------|-------|--------|---------|
| Dev/Test | kafka.t3.small | 2 | 2 GB | Up to 5 Gbps |
| Staging | kafka.m5.large | 2 | 8 GB | Up to 10 Gbps |
| Production | kafka.m5.2xlarge | 8 | 32 GB | Up to 10 Gbps |
| High-throughput | kafka.m5.4xlarge | 16 | 64 GB | Up to 10 Gbps |

## Dependencies

- AWS Provider >= 5.0
- Existing VPC with at least 3 private subnets (for 3-broker cluster)
- Optional: Route53 private hosted zone

## Related Modules

- [kafka-data-plane](../kafka-data-plane) - Creates topics and ACLs
- [msk-connect](../msk-connect) - Deploys connectors to this cluster
- [ecs-service](../ecs-service) - Services that connect to this cluster
