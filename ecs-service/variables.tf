# General
variable "app_name" {
  description = "App name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Networking
variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks and EFS mount targets"
  type        = list(string)
}

# ECS Cluster
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = null
}

variable "container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

# TLS/SSL Certificate
variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS listeners"
  type        = string
  default     = null
}

# Services Configuration
variable "services" {
  description = "Map of ECS services to create"
  type = map(object({
    # Container Image
    image = string

    # Resource allocation
    cpu    = number
    memory = number

    # Scaling
    desired_count = optional(number, 1)

    # Container configuration
    container_port    = number
    health_check_path = string

    # Command/Entrypoint overrides
    entrypoint = optional(list(string), null)
    command    = optional(list(string), null)

    # Environment variables
    environment = optional(list(object({
      name  = string
      value = string
    })), [])

    # Secrets from SSM or Secrets Manager
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })), [])

    # ALB configuration
    enable_alb               = optional(bool, true)
    alb_listener_port        = optional(number, 443)
    alb_health_check_matcher = optional(string, "200")
    alb_deregistration_delay = optional(number, 30)

    # Route53 configuration
    enable_route53      = optional(bool, true)
    route53_zone_id     = optional(string, null)
    route53_record_name = optional(string, null)

    # EFS volumes
    efs_volumes = optional(map(object({
      container_path = string
      read_only      = optional(bool, false)
    })), {})

    # Logging
    log_retention_days = optional(number, 30)

    # Health check grace period
    health_check_grace_period = optional(number, 60)

    # Enable ECS Exec for debugging
    enable_execute_command = optional(bool, true)

    # Additional security group IDs to attach
    additional_security_group_ids = optional(list(string), [])

    # Custom health check for container
    container_health_check = optional(object({
      command     = list(string)
      interval    = optional(number, 30)
      timeout     = optional(number, 5)
      retries     = optional(number, 3)
      startPeriod = optional(number, 60)
    }), null)
  }))

  validation {
    condition = alltrue([
      for k, v in var.services : contains([256, 512, 1024, 2048, 4096], v.cpu)
    ])
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

# EFS Configuration
variable "efs_performance_mode" {
  description = "EFS performance mode (generalPurpose or maxIO)"
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "EFS throughput mode (bursting or provisioned)"
  type        = string
  default     = "bursting"
}

# IAM
variable "task_role_additional_policies" {
  description = "Additional IAM policy ARNs to attach to task role"
  type        = list(string)
  default     = []
}

variable "iam_permissions_boundary_arn" {
  description = "ARN of the IAM permissions boundary to attach to roles"
  type        = string
  default     = null
}

# Security Groups
variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access ALB"
  type        = list(string)
  default     = []
}

variable "alb_ingress_security_group_ids" {
  description = "Security group IDs allowed to access ALB"
  type        = list(string)
  default     = []
}

variable "ecs_additional_ingress_security_group_ids" {
  description = "Additional security group IDs that can access ECS tasks directly"
  type        = list(string)
  default     = []
}
