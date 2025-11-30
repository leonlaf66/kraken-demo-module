resource "aws_ecs_task_definition" "this" {
  for_each = var.services

  family                   = "${var.app_name}-${var.environment}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  dynamic "volume" {
    for_each = each.value.efs_volumes

    content {
      name = "${each.key}-${volume.key}"

      efs_volume_configuration {
        file_system_id     = aws_efs_file_system.this.id
        transit_encryption = "ENABLED"

        authorization_config {
          access_point_id = aws_efs_access_point.this["${each.key}-${volume.key}"].id
          iam             = "ENABLED"
        }
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      essential = true
      cpu       = each.value.cpu
      memory    = each.value.memory

      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = each.value.container_port
          protocol      = "tcp"
        }
      ]

      entryPoint = each.value.entrypoint
      command    = each.value.command

      environment = each.value.environment
      secrets     = each.value.secrets

      mountPoints = [
        for volume_name, volume in each.value.efs_volumes : {
          sourceVolume  = "${each.key}-${volume_name}"
          containerPath = volume.container_path
          readOnly      = volume.read_only
        }
      ]

      healthCheck = each.value.container_health_check != null ? {
        command     = each.value.container_health_check.command
        interval    = each.value.container_health_check.interval
        timeout     = each.value.container_health_check.timeout
        retries     = each.value.container_health_check.retries
        startPeriod = each.value.container_health_check.startPeriod
      } : null

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.services[each.key].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = each.key
        }
      }
    }
  ])

  tags = merge(
    local.default_tags,
    {
      Name    = "${var.app_name}-${var.environment}-${each.key}-task"
      Service = each.key
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
