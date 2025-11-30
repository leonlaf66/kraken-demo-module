locals {
  name_prefix = "${var.app_name}-${var.environment}"

  alb_ingress_rules = merge(
    # CIDR rules
    {
      for pair in setproduct(keys(local.services_with_alb), var.alb_ingress_cidr_blocks) :
      "${pair[0]}-cidr-${index(var.alb_ingress_cidr_blocks, pair[1])}" => {
        service_name = pair[0]
        cidr_block   = pair[1]
        sg_id        = null
      }
    },
    # Security group rules
    {
      for pair in setproduct(keys(local.services_with_alb), var.alb_ingress_security_group_ids) :
      "${pair[0]}-sg-${index(var.alb_ingress_security_group_ids, pair[1])}" => {
        service_name = pair[0]
        cidr_block   = null
        sg_id        = pair[1]
      }
    },
    # Default VPC CIDR if no rules specified
    length(var.alb_ingress_cidr_blocks) == 0 && length(var.alb_ingress_security_group_ids) == 0 ? {
      for k, v in local.services_with_alb : "${k}-vpc" => {
        service_name = k
        cidr_block   = data.aws_vpc.selected.cidr_block
        sg_id        = null
      }
    } : {}
  )
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.name_prefix}-ecs-tasks-sg"
  description = "ECS Fargate tasks"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-ecs-tasks-sg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  for_each = local.services_with_alb

  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "From ${each.key} ALB"
  from_port                    = each.value.container_port
  to_port                      = each.value.container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb[each.key].id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_internal" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "Internal ECS communication"
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_tasks.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_additional" {
  for_each = toset(var.ecs_additional_ingress_security_group_ids)

  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "From additional SG"
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = each.value
}

resource "aws_vpc_security_group_egress_rule" "ecs_outbound" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ALB Security Groups (one per service)
resource "aws_security_group" "alb" {
  for_each = local.services_with_alb

  name        = "${local.name_prefix}-${each.key}-alb-sg"
  description = "${each.key} ALB"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-${each.key}-alb-sg", Service = each.key })

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress" {
  for_each = local.alb_ingress_rules

  security_group_id            = aws_security_group.alb[each.value.service_name].id
  description                  = each.value.cidr_block != null ? "From ${each.value.cidr_block}" : "From SG"
  from_port                    = local.services_with_alb[each.value.service_name].alb_listener_port
  to_port                      = local.services_with_alb[each.value.service_name].alb_listener_port
  ip_protocol                  = "tcp"
  cidr_ipv4                    = each.value.cidr_block
  referenced_security_group_id = each.value.sg_id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  for_each = local.services_with_alb

  security_group_id            = aws_security_group.alb[each.key].id
  description                  = "To ECS tasks"
  from_port                    = each.value.container_port
  to_port                      = each.value.container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_tasks.id
}

# EFS Security Group
resource "aws_security_group" "efs" {
  name        = "${local.name_prefix}-efs-sg"
  description = "EFS mount targets"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-efs-sg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_ecs" {
  security_group_id            = aws_security_group.efs.id
  description                  = "NFS from ECS"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_tasks.id
}
