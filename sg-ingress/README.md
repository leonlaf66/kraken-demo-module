# Security Group Ingress Module

Utility module for creating security group ingress rules separately from security groups.

## Purpose

Breaks circular dependencies when multiple modules create security groups that need to reference each other.

## Usage

```hcl
module "sg_ingress" {
  source = "git::https://github.com/leonlaf66/kraken-demo-module.git//sg-ingress?ref=main"

  ingress_rules = {
    "rds-from-debezium" = {
      description                  = "PostgreSQL from Debezium"
      security_group_id            = var.database_security_group_id
      referenced_security_group_id = module.debezium.security_group_id
      from_port                    = 5432
      to_port                      = 5432
      ip_protocol                  = "tcp"
    }

    "msk-from-vpc" = {
      description       = "Kafka from VPC"
      security_group_id = var.msk_security_group_id
      cidr_ipv4         = "10.0.0.0/16"
      from_port         = 9096
      to_port           = 9096
      ip_protocol       = "tcp"
    }
  }
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| ingress_rules | map(object) | yes | Ingress rules |

Each rule must have either `cidr_ipv4` OR `referenced_security_group_id`, not both.

## Outputs

| Name | Description |
|------|-------------|
| ingress_rule_ids | Rule IDs by name |
| ingress_rule_arns | Rule ARNs by name |
| rule_count | Total rules created |
