# ECS Service Module

## Overview

This module provisions a complete ECS Fargate infrastructure for running multiple containerized services with ALB, EFS, Route53 integration, and CloudWatch logging.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                            ECS Service Module                                 │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                          ECS Cluster                                     │ │
│  │                    (Container Insights Enabled)                          │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                    │                                          │
│    ┌───────────────────────────────┼───────────────────────────────────────┐ │
│    │                               │                               │       │ │
│    ▼                               ▼                               ▼       │ │
│  ┌──────────────┐            ┌──────────────┐            ┌──────────────┐ │ │
│  │   Service 1  │            │   Service 2  │            │   Service N  │ │ │
│  │  (Fargate)   │            │  (Fargate)   │            │  (Fargate)   │ │ │
│  ├──────────────┤            ├──────────────┤            ├──────────────┤ │ │
│  │     ALB      │            │     ALB      │            │     ALB      │ │ │
│  │   Listener   │            │   Listener   │            │   Listener   │ │ │
│  ├──────────────┤            ├──────────────┤            ├──────────────┤ │ │
│  │   Route53    │            │   Route53    │            │   Route53    │ │ │
│  │   Record     │            │   Record     │            │   Record     │ │ │
│  └──────────────┘            └──────────────┘            └──────────────┘ │ │
│         │                           │                           │          │ │
│         └───────────────────────────┼───────────────────────────┘          │ │
│                                     │                                       │ │
│  ┌──────────────────────────────────┼──────────────────────────────────────┐│ │
│  │                           EFS File System                                ││ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                     ││ │
│  │  │ Access Pt 1 │  │ Access Pt 2 │  │ Access Pt N │                     ││ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                     ││ │
│  └─────────────────────────────────────────────────────────────────────────┘│ │
│                                                                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │
│  │  IAM Roles      │  │ Security Groups │  │ CloudWatch Logs │              │
│  │ - Execution     │  │ - ALB (per svc) │  │ - Per Service   │              │
│  │ - Task          │  │ - ECS Tasks     │  │                 │              │
│  │                 │  │ - EFS           │  │                 │              │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘              │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **Multi-Service Support**: Deploy multiple services from a single module call
- **Per-Service ALB**: Each service gets its own Application Load Balancer
- **EFS Integration**: Shared or service-specific persistent storage
- **Route53 DNS**: Automatic DNS record creation
- **CloudWatch Logging**: Centralized logs with configurable retention
- **ECS Exec**: Debug containers directly
- **HTTPS Support**: ACM certificate integration

## Usage

```hcl
module "streaming_services" {
  source = "git::https://github.com/your-org/kraken-demo-module.git//ecs-service?ref=v1.0.0"

  app_name       = "kraken-demo"
  environment    = "dev"
  aws_region     = "us-east-1"
  aws_account_id = "123456789012"
  common_tags    = var.common_tags

  # Networking
  vpc_id             = data.aws_vpc.selected.id
  private_subnet_ids = data.aws_subnets.private.ids

  # ECS Cluster
  cluster_name       = "kraken-demo-dev-streaming"
  container_insights = true

  # HTTPS
  acm_certificate_arn = var.acm_certificate_arn

  # Services
  services = {
    schema-registry = {
      image             = "123456789012.dkr.ecr.us-east-1.amazonaws.com/schema-registry:v7.5.0"
      cpu               = 1024
      memory            = 2048
      container_port    = 8081
      health_check_path = "/subjects"
      enable_alb        = true
      alb_listener_port = 8081
      enable_route53    = true
      route53_zone_id   = var.route53_private_zone_id

      environment = [
        { name = "SCHEMA_REGISTRY_HOST_NAME", value = "0.0.0.0" }
      ]
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `app_name` | Application name | `string` | n/a | yes |
| `environment` | Environment name | `string` | n/a | yes |
| `aws_region` | AWS region | `string` | n/a | yes |
| `aws_account_id` | AWS account ID | `string` | n/a | yes |
| `common_tags` | Common tags | `map(string)` | `{}` | no |
| `vpc_id` | VPC ID | `string` | n/a | yes |
| `private_subnet_ids` | Private subnet IDs | `list(string)` | n/a | yes |
| `cluster_name` | ECS cluster name | `string` | `null` | no |
| `container_insights` | Enable Container Insights | `bool` | `true` | no |
| `acm_certificate_arn` | ACM certificate ARN | `string` | `null` | no |
| `services` | Map of services to create | See below | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | ECS cluster ID |
| `cluster_arn` | ECS cluster ARN |
| `cluster_name` | ECS cluster name |
| `services` | Map of ECS service details |
| `service_arns` | Map of service ARNs |
| `service_endpoints` | Map of service endpoint URLs |
| `alb_arns` | Map of ALB ARNs |
| `alb_dns_names` | Map of ALB DNS names |
| `route53_records` | Map of Route53 FQDNs |
| `efs_file_system_id` | EFS file system ID |
| `ecs_tasks_security_group_id` | ECS tasks security group ID |

## Dependencies

- AWS Provider >= 5.0
- Existing VPC with private subnets
- ACM certificate (for HTTPS)
- Route53 private hosted zone (optional)

## Related Modules

- [msk](../msk) - MSK cluster these services connect to
- [msk-connect](../msk-connect) - Connectors that may use these services
