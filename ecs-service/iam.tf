#TASK EXECUTION ROLE
resource "aws_iam_role" "ecs_execution" {
  name                 = "${var.app_name}-${var.environment}-ecs-execution-role"
  assume_role_policy   = data.aws_iam_policy_document.ecs_assume_role.json
  permissions_boundary = var.iam_permissions_boundary_arn

  tags = merge(
    local.default_tags,
    {
      Name = "${var.app_name}-${var.environment}-ecs-execution-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_execution_ssm" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_execution_ssm.arn
}

resource "aws_iam_role_policy_attachment" "ecs_execution_secrets" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_execution_secrets.arn
}

resource "aws_iam_role_policy_attachment" "ecs_execution_kms" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_execution_kms.arn
}

resource "aws_iam_role_policy_attachment" "ecs_execution_logs" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_execution_logs.arn
}

###TASK ROLE
resource "aws_iam_role" "ecs_task" {
  name                 = "${var.app_name}-${var.environment}-ecs-task-role"
  assume_role_policy   = data.aws_iam_policy_document.ecs_assume_role.json
  permissions_boundary = var.iam_permissions_boundary_arn

  tags = merge(
    local.default_tags,
    {
      Name = "${var.app_name}-${var.environment}-ecs-task-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_task_ssm" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_ssm.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_exec.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_cloudwatch" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_efs" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_efs.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_additional" {
  for_each = toset(var.task_role_additional_policies)

  role       = aws_iam_role.ecs_task.name
  policy_arn = each.value
}
