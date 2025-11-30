# Cluster Outputs
output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

# Service Outputs
output "services" {
  description = "Map of ECS service details"
  value = {
    for k, v in aws_ecs_service.this : k => {
      id            = v.id
      name          = v.name
      desired_count = v.desired_count
    }
  }
}

output "service_arns" {
  description = "Map of ECS service ARNs by service name"
  value = {
    for k, v in aws_ecs_service.this : k => v.id
  }
}

output "task_definitions" {
  description = "Map of task definition ARNs"
  value = {
    for k, v in aws_ecs_task_definition.this : k => {
      arn      = v.arn
      family   = v.family
      revision = v.revision
    }
  }
}

# ALB Outputs
output "alb_arns" {
  description = "Map of ALB ARNs by service name"
  value = {
    for k, v in aws_lb.this : k => v.arn
  }
}

output "alb_dns_names" {
  description = "Map of ALB DNS names by service name"
  value = {
    for k, v in aws_lb.this : k => v.dns_name
  }
}

output "target_group_arns" {
  description = "Map of target group ARNs by service name"
  value = {
    for k, v in aws_lb_target_group.this : k => v.arn
  }
}

# Route53 Outputs
output "route53_records" {
  description = "Map of Route53 record FQDNs"
  value = {
    for k, v in aws_route53_record.alb : k => v.fqdn
  }
}

# EFS Outputs
output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.this.id
}

output "efs_file_system_arn" {
  description = "EFS file system ARN"
  value       = aws_efs_file_system.this.arn
}

output "efs_access_points" {
  description = "Map of EFS access point IDs"
  value = {
    for k, v in aws_efs_access_point.this : k => v.id
  }
}

# Security Group Outputs
output "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "alb_security_group_ids" {
  description = "Map of ALB security group IDs by service name"
  value = {
    for k, v in aws_security_group.alb : k => v.id
  }
}

output "efs_security_group_id" {
  description = "Security group ID for EFS"
  value       = aws_security_group.efs.id
}

# IAM Outputs
output "execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_execution.arn
}

output "task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task.arn
}

# CloudWatch Outputs
output "log_group_names" {
  description = "Map of CloudWatch log group names by service"
  value = {
    for k, v in aws_cloudwatch_log_group.services : k => v.name
  }
}

# Service Endpoints
output "service_endpoints" {
  description = "Map of all service endpoints"
  value = {
    for k, v in var.services : k => {
      alb_dns  = v.enable_alb ? aws_lb.this[k].dns_name : null
      dns_name = v.enable_route53 && v.route53_zone_id != null ? aws_route53_record.alb[k].fqdn : null
      port     = v.alb_listener_port
      protocol = local.use_https ? "https" : "http"
      url = v.enable_alb ? (
        v.enable_route53 && v.route53_zone_id != null
        ? "${local.use_https ? "https" : "http"}://${aws_route53_record.alb[k].fqdn}:${v.alb_listener_port}"
        : "${local.use_https ? "https" : "http"}://${aws_lb.this[k].dns_name}:${v.alb_listener_port}"
      ) : null
    }
  }
}
