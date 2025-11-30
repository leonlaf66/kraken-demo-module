resource "aws_ecs_service" "this" {
  for_each = var.services

  name            = "${var.app_name}-${var.environment}-${each.key}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count

  launch_type         = "FARGATE"
  platform_version    = "LATEST"
  scheduling_strategy = "REPLICA"

  enable_execute_command = each.value.enable_execute_command

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = each.value.enable_alb ? each.value.health_check_grace_period : null

  propagate_tags = "TASK_DEFINITION"

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = concat(
      [aws_security_group.ecs_tasks.id],
      each.value.additional_security_group_ids
    )
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = each.value.enable_alb ? [1] : []

    content {
      target_group_arn = aws_lb_target_group.this[each.key].arn
      container_name   = each.key
      container_port   = each.value.container_port
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = merge(
    local.default_tags,
    {
      Name    = "${var.app_name}-${var.environment}-${each.key}-service"
      Service = each.key
    }
  )

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [
    aws_lb_listener.https,
    aws_lb_listener.http,
    aws_efs_mount_target.this,
    aws_iam_role_policy.ecs_task,
    aws_iam_role_policy.ecs_execution_custom
  ]
}
