# Kafka Data Plane Module

Manages Kafka topics and ACLs using the Mongey Kafka provider.

## Resources Created

- Kafka topics with custom configurations
- Kafka ACLs for SCRAM users

## Usage

```hcl
module "kafka" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//kafka-data-plane?ref=main"

  bootstrap_servers    = var.msk_bootstrap_brokers_nlb
  kafka_admin_username = "admin"
  kafka_admin_password = local.kafka_admin_creds.password
  skip_tls_verify      = var.env == "dev"

  msk_cluster_arn  = var.msk_cluster_arn
  msk_cluster_name = var.msk_cluster_name

  topics = [
    {
      name               = "cdc.trades.mnpi"
      replication_factor = 3
      partitions         = 6
      config = {
        "retention.ms"     = "604800000"
        "compression.type" = "lz4"
      }
    }
  ]

  user_acls = {
    admin = [
      { resource_name = "*", resource_type = "Topic", operation = "All" }
    ]
    debezium = [
      { resource_name = "cdc.*", resource_type = "Topic", operation = "Write" }
    ]
  }
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| bootstrap_servers | string | yes | Kafka bootstrap servers |
| kafka_admin_username | string | yes | Admin username |
| kafka_admin_password | string | yes | Admin password |
| msk_cluster_arn | string | yes | MSK cluster ARN |
| topics | list(object) | no | Topics to create |
| user_acls | map(list(object)) | no | ACLs by username |

## Outputs

| Name | Description |
|------|-------------|
| topic_names | List of created topic names |
| topic_details | Topic configuration details |
| acl_count | Number of ACLs created |
| users_with_acls | Users with ACL permissions |

## Provider

Uses `mongey/kafka` provider v0.5.4. Configured in `providers.tf`.
