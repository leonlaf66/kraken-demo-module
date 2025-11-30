locals {
  # Cluster name
  cluster_name = coalesce(var.cluster_name, "${var.app_name}-${var.environment}-cluster")

  # HTTPS enabled if certificate ARN is provided
  use_https = var.acm_certificate_arn != null

  # Flatten EFS volumes for access point creation
  efs_access_points = merge([
    for service_name, service in var.services : {
      for volume_name, volume in service.efs_volumes :
      "${service_name}-${volume_name}" => {
        service_name   = service_name
        volume_name    = volume_name
        container_path = volume.container_path
        read_only      = volume.read_only
      }
    }
  ]...)

  # Services that need ALB
  services_with_alb = {
    for k, v in var.services : k => v
    if v.enable_alb
  }

  # Services that need Route53
  services_with_route53 = {
    for k, v in var.services : k => v
    if v.enable_alb && v.enable_route53 && v.route53_zone_id != null
  }

  # Common tags
  default_tags = merge(
    var.common_tags,
    {
      App     = var.app_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

################################################################################
# Data Source - VPC CIDR for default security group rules
################################################################################

data "aws_vpc" "selected" {
  id = var.vpc_id
}
