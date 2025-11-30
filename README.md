# Kraken Demo Modules

Terraform modules for building a secure, auditable AWS Data Lake platform.

## Modules

| Module | Description |
|--------|-------------|
| [storage](./storage) | S3 Data Lake with MNPI/Public isolation, Glue, CloudTrail |
| [database](./database) | PostgreSQL RDS with CDC-enabled parameters |
| [msk](./msk) | Amazon MSK cluster with SCRAM auth and NLB |
| [msk-connect](./msk-connect) | MSK Connect connector (source/sink) |
| [kafka-data-plane](./kafka-data-plane) | Kafka topics and ACLs |
| [athena](./athena) | Athena workgroups with RBAC |
| [ecs-service](./ecs-service) | ECS Fargate services with ALB, EFS |
| [sg-ingress](./sg-ingress) | Security group ingress rules |

## Architecture

```
                                    ┌─────────────────────────────────────┐
                                    │         ECS (ecs-service)           │
                                    │  Schema Registry, Cruise Control,   │
                                    │     Prometheus, Alertmanager        │
                                    └──────────────────┬──────────────────┘
                                                       │
                                              (schema management)
                                                       │
                                                       ▼
┌─────────────┐    ┌─────────────────────┐    ┌─────────────┐    ┌─────────────────────┐    ┌─────────────┐
│  RDS        │───▶│  MSK Connect        │───▶│    MSK      │───▶│  MSK Connect        │───▶│  S3 Data    │
│  (database) │    │  Debezium Source    │    │   (msk)     │    │  S3 Sink            │    │  Lake       │
│             │CDC │  (msk-connect)      │    │             │    │  (msk-connect)      │    │  (storage)  │
└─────────────┘    └─────────────────────┘    └─────────────┘    └─────────────────────┘    └──────┬──────┘
                                                                                                   │
                                                                                                   │
                                                                                           ┌───────▼───────┐
                                                                                           │    Athena     │
                                                                                           │   (athena)    │
                                                                                           └───────────────┘
```

**Data Flow:**
1. **RDS → Debezium**: CDC captures changes from PostgreSQL
2. **Debezium → MSK**: Events published to Kafka topics (MNPI/Public separated)
3. **MSK → S3 Sink**: S3 Sink connectors write to Data Lake buckets
4. **S3 → Athena**: Query engine for analytics

**Supporting Services (ECS):**
- Schema Registry: Manages Avro/JSON schemas for Kafka
- Cruise Control: Kafka cluster management and rebalancing
- Prometheus/Alertmanager: Monitoring and alerting

## Usage

These modules are designed to be used with Spacelift stacks:

1. **infra stack**: storage, database, msk
2. **data-plane stack**: kafka-data-plane, msk-connect, athena, ecs-service

```hcl
# Example: infra stack
module "storage" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//storage?ref=main"
  # ...
}

module "database" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//database?ref=main"
  # ...
}

module "msk" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//msk?ref=main"
  # ...
}
```

## Requirements

- Terraform >= 1.5.0
- AWS Provider ~> 5.0
- Kafka Provider 0.5.4 (for kafka-data-plane)

## Security Features

- **Encryption**: KMS at-rest, TLS in-transit
- **Authentication**: SCRAM-SHA-512 for Kafka, IAM for AWS
- **Authorization**: MNPI/Public data isolation, RBAC via Athena workgroups
- **Auditing**: CloudTrail for S3 data access
- **Network**: Private subnets only, security group isolation
- **Monitoring**: Prometheus metrics collection, Alertmanager for security alerts
