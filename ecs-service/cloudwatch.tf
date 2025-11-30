resource "aws_cloudwatch_log_group" "services" {
  for_each = var.services

  name              = "/ecs/${var.app_name}-${var.environment}/${each.key}"
  retention_in_days = each.value.log_retention_days

  tags = merge(
    local.default_tags,
    {
      Name    = "${var.app_name}-${var.environment}-${each.key}-logs"
      Service = each.key
    }
  )
}
