# ECS Service Module

ECS Fargate cluster with multiple services, ALB, EFS, and Route53.

## Resources Created

- ECS Fargate cluster
- ECS services and task definitions
- Application Load Balancers
- EFS file system with access points
- Route53 records
- CloudWatch log groups
- IAM roles (execution and task)
- Security groups

## Usage

```hcl
module "streaming_services" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//ecs-service?ref=main"

  app_name       = "kraken-demo"
  environment    = "dev"
  aws_region     = "us-east-1"
  aws_account_id = "123456789012"

  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids

  acm_certificate_arn = var.acm_certificate_arn

  services = {
    schema-registry = {
      image             = "confluentinc/cp-schema-registry:7.5.0"
      cpu               = 1024
      memory            = 2048
      container_port    = 8081
      health_check_path = "/subjects"
      enable_alb        = true
      enable_route53    = true
      route53_zone_id   = var.route53_zone_id

      environment = [
        { name = "SCHEMA_REGISTRY_HOST_NAME", value = "0.0.0.0" }
      ]

      efs_volumes = {
        data = {
          container_path = "/var/lib/schema-registry"
          read_only      = false
        }
      }
    }
  }
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| app_name | string | yes | Application name |
| environment | string | yes | Environment |
| vpc_id | string | yes | VPC ID |
| private_subnet_ids | list(string) | yes | Subnet IDs |
| services | map(object) | yes | Service configurations |
| acm_certificate_arn | string | no | ACM cert for HTTPS |

## Service Configuration

Each service supports:
- `image`: Container image URI
- `cpu`/`memory`: Resource allocation
- `container_port`: Container port
- `health_check_path`: ALB health check
- `environment`: Environment variables
- `secrets`: Secrets from SSM/Secrets Manager
- `efs_volumes`: EFS volume mounts
- `command`/`entrypoint`: Override defaults

## Outputs

| Name | Description |
|------|-------------|
| cluster_id/arn/name | ECS cluster info |
| service_arns | Service ARNs by name |
| service_endpoints | URLs by service name |
| ecs_tasks_security_group_id | Tasks security group |
