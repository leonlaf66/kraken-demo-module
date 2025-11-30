resource "aws_ecs_cluster" "this" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = merge(
    local.default_tags,
    {
      Name = local.cluster_name
    }
  )
}
