# Kafka Data Plane Module

## Overview

This module manages Kafka topics and ACLs using the Kafka Terraform provider. It creates topics with specific configurations and sets up least-privilege ACLs for SCRAM users.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         Kafka Data Plane Module                           │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                         Kafka Topics                                 │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │ │
│  │  │ cdc.trades  │  │ cdc.orders  │  │ cdc.market  │                 │ │
│  │  │    .mnpi    │  │    .mnpi    │  │   _data     │                 │ │
│  │  │             │  │             │  │  .public    │                 │ │
│  │  │ P:6 R:3     │  │ P:6 R:3     │  │ P:9 R:3     │                 │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                 │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                           Kafka ACLs                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐│ │
│  │  │  User: admin                                                    ││ │
│  │  │  - Cluster: All operations                                      ││ │
│  │  │  - Topics: All (*) - All operations                             ││ │
│  │  │  - Groups: All (*) - All operations                             ││ │
│  │  └─────────────────────────────────────────────────────────────────┘│ │
│  │  ┌─────────────────────────────────────────────────────────────────┐│ │
│  │  │  User: debezium                                                 ││ │
│  │  │  - Topics: cdc.* - Write, Describe, Create                      ││ │
│  │  │  - Topics: schema-changes.* - Read, Write, Describe, Create     ││ │
│  │  │  - Cluster: IdempotentWrite                                     ││ │
│  │  │  - Groups: connect-debezium-* - Read                            ││ │
│  │  └─────────────────────────────────────────────────────────────────┘│ │
│  │  ┌─────────────────────────────────────────────────────────────────┐│ │
│  │  │  User: s3_sink_mnpi                                             ││ │
│  │  │  - Topics: cdc.*.mnpi - Read, Describe                          ││ │
│  │  │  - Groups: connect-s3-sink-raw-mnpi-* - Read                    ││ │
│  │  └─────────────────────────────────────────────────────────────────┘│ │
│  │  ┌─────────────────────────────────────────────────────────────────┐│ │
│  │  │  User: s3_sink_public                                           ││ │
│  │  │  - Topics: cdc.*.public - Read, Describe                        ││ │
│  │  │  - Groups: connect-s3-sink-raw-public-* - Read                  ││ │
│  │  └─────────────────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Topic Management**: Create topics with custom partitions, replication, and configs
- **ACL Management**: Least-privilege ACLs per SCRAM user
- **Validation**: Input validation for topic and ACL configurations
- **Idempotent**: Safe to run multiple times

## Prerequisites

This module requires the Kafka Terraform provider configured with admin credentials:

```hcl
# providers.tf
terraform {
  required_providers {
    kafka = {
      source  = "Mongey/kafka"
      version = "~> 0.7"
    }
  }
}

provider "kafka" {
  bootstrap_servers = [var.msk_bootstrap_brokers_nlb]
  
  sasl_username = local.kafka_admin_creds.username
  sasl_password = local.kafka_admin_creds.password
  sasl_mechanism = "scram-sha512"
  
  tls_enabled       = true
  skip_tls_verify   = var.env == "dev"
}
```

## Usage

```hcl
module "kafka" {
  source = "git::https://github.com/your-org/kraken-demo-module.git//kafka-data-plane?ref=v1.0.0"

  bootstrap_servers    = var.msk_bootstrap_brokers_nlb
  kafka_admin_username = local.kafka_admin_creds.username
  kafka_admin_password = local.kafka_admin_creds.password
  skip_tls_verify      = var.env == "dev"

  msk_cluster_arn  = var.msk_cluster_arn
  msk_cluster_name = var.msk_cluster_name
  common_tags      = var.common_tags

  # Topics
  topics = [
    # CDC Topics - MNPI (Sensitive)
    {
      name               = "cdc.trades.mnpi"
      replication_factor = 3
      partitions         = 6
      config = {
        "retention.ms"        = "604800000"   # 7 days
        "compression.type"    = "lz4"
        "min.insync.replicas" = "2"
        "cleanup.policy"      = "delete"
      }
    },
    {
      name               = "cdc.orders.mnpi"
      replication_factor = 3
      partitions         = 6
      config = {
        "retention.ms"        = "604800000"
        "compression.type"    = "lz4"
        "min.insync.replicas" = "2"
      }
    },
    
    # CDC Topics - Public
    {
      name               = "cdc.market_data.public"
      replication_factor = 3
      partitions         = 9
      config = {
        "retention.ms"        = "604800000"
        "compression.type"    = "snappy"
        "min.insync.replicas" = "2"
      }
    },
    
    # Debezium Internal
    {
      name               = "schema-changes.kraken-cdc"
      replication_factor = 3
      partitions         = 1
      config = {
        "retention.ms"   = "-1"  # Infinite
        "cleanup.policy" = "delete"
      }
    }
  ]

  # ACLs
  user_acls = {
    # Admin - Full Access
    admin = [
      {
        resource_name = "kafka-cluster"
        resource_type = "Cluster"
        operation     = "All"
      },
      {
        resource_name = "*"
        resource_type = "Topic"
        operation     = "All"
      },
      {
        resource_name = "*"
        resource_type = "Group"
        operation     = "All"
      }
    ]

    # Debezium - CDC Source
    debezium = [
      {
        resource_name = "cdc.*"
        resource_type = "Topic"
        operation     = "Write"
      },
      {
        resource_name = "cdc.*"
        resource_type = "Topic"
        operation     = "Create"
      },
      {
        resource_name = "schema-changes.*"
        resource_type = "Topic"
        operation     = "Read"
      },
      {
        resource_name = "schema-changes.*"
        resource_type = "Topic"
        operation     = "Write"
      },
      {
        resource_name = "kafka-cluster"
        resource_type = "Cluster"
        operation     = "IdempotentWrite"
      },
      {
        resource_name = "connect-debezium-*"
        resource_type = "Group"
        operation     = "Read"
      }
    ]

    # S3 Sink MNPI - Read only MNPI topics
    s3_sink_mnpi = [
      {
        resource_name = "cdc.trades.mnpi"
        resource_type = "Topic"
        operation     = "Read"
      },
      {
        resource_name = "cdc.orders.mnpi"
        resource_type = "Topic"
        operation     = "Read"
      },
      {
        resource_name = "connect-s3-sink-raw-mnpi-*"
        resource_type = "Group"
        operation     = "Read"
      }
    ]

    # S3 Sink Public - Read only public topics
    s3_sink_public = [
      {
        resource_name = "cdc.market_data.public"
        resource_type = "Topic"
        operation     = "Read"
      },
      {
        resource_name = "connect-s3-sink-raw-public-*"
        resource_type = "Group"
        operation     = "Read"
      }
    ]
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `bootstrap_servers` | Kafka bootstrap servers | `string` | n/a | yes |
| `kafka_admin_username` | Admin username | `string` | `"admin"` | no |
| `kafka_admin_password` | Admin password | `string` | n/a | yes |
| `skip_tls_verify` | Skip TLS verification | `bool` | `false` | no |
| `msk_cluster_arn` | MSK cluster ARN | `string` | n/a | yes |
| `msk_cluster_name` | MSK cluster name | `string` | n/a | yes |
| `common_tags` | Common tags | `map(string)` | `{}` | no |
| `topics` | List of topics | See below | `[]` | no |
| `user_acls` | Map of user ACLs | See below | `{}` | no |

### Topic Configuration

```hcl
topics = [
  {
    name               = string       # Topic name
    replication_factor = number       # 1-3
    partitions         = number       # 1-100
    config = {
      "retention.ms"        = string  # Message retention
      "compression.type"    = string  # none, gzip, snappy, lz4, zstd
      "min.insync.replicas" = string  # Min ISR
      "cleanup.policy"      = string  # delete, compact
      # ... other Kafka topic configs
    }
  }
]
```

### ACL Configuration

```hcl
user_acls = {
  username = [
    {
      resource_name   = string  # Topic/Group name or "*" for wildcard
      resource_type   = string  # "Topic", "Group", or "Cluster"
      operation       = string  # See operations below
      permission_type = string  # "Allow" (default) or "Deny"
      host            = string  # "*" (default) or specific IP
    }
  ]
}
```

### Valid ACL Operations

| Operation | Description |
|-----------|-------------|
| `Read` | Consume from topic |
| `Write` | Produce to topic |
| `Create` | Create topic |
| `Delete` | Delete topic |
| `Alter` | Alter topic config |
| `Describe` | Describe topic |
| `ClusterAction` | Cluster-level actions |
| `DescribeConfigs` | Describe configurations |
| `AlterConfigs` | Alter configurations |
| `IdempotentWrite` | Idempotent producer |
| `All` | All operations |

## Outputs

| Name | Description |
|------|-------------|
| `topics` | Map of created topics |
| `acls` | Map of created ACLs |

## Topic Naming Conventions

| Pattern | Example | Description |
|---------|---------|-------------|
| `cdc.{table}.mnpi` | `cdc.trades.mnpi` | CDC topic for MNPI data |
| `cdc.{table}.public` | `cdc.market_data.public` | CDC topic for public data |
| `schema-changes.{source}` | `schema-changes.kraken-cdc` | Debezium schema history |

## Security Considerations

1. **Least Privilege**: Each connector gets only required topic access
2. **No Wildcard for Sink**: S3 sink connectors explicitly list topics
3. **Consumer Groups**: Scoped to connector-specific prefixes
4. **IdempotentWrite**: Required for exactly-once semantics

## ACL Best Practices

1. **Separate Users**: Each connector has its own SCRAM user
2. **Explicit Topics**: Avoid wildcards for sink connectors
3. **Consumer Groups**: Match connector name patterns
4. **Describe Permission**: Always include with Read/Write

## Troubleshooting

### ACL Not Working
1. Verify username matches SCRAM secret exactly
2. Check resource pattern matches topic name
3. Ensure operation is correct for use case

### Topic Creation Failed
1. Check replication factor <= broker count
2. Verify admin user has Create permission
3. Check for existing topic with same name

## Dependencies

- Kafka Provider (Mongey/kafka) ~> 0.7
- Existing MSK cluster with SCRAM enabled
- Admin credentials from Secrets Manager

## Related Modules

- [msk](../msk) - Creates the MSK cluster and SCRAM users
- [msk-connect](../msk-connect) - Connectors that use these topics/ACLs
