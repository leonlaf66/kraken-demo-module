data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS Execution Role - Policy Documents
data "aws_iam_policy_document" "ecs_execution_ssm" {
  statement {
    sid    = "SSMParameterAccess"
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:GetParametersByPath"
    ]
    resources = ["arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/${var.app_name}/*"]
  }
}

data "aws_iam_policy_document" "ecs_execution_secrets" {
  statement {
    sid       = "SecretsManagerAccess"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.app_name}/*"]
  }
}

data "aws_iam_policy_document" "ecs_execution_kms" {
  statement {
    sid       = "KMSDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.aws_region}.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_execution_logs" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/ecs/${var.app_name}-${var.environment}/*"]
  }
}

# ECS Task Role - Policy Documents
data "aws_iam_policy_document" "ecs_task_ssm" {
  statement {
    sid    = "SSMParameterRead"
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:GetParametersByPath"
    ]
    resources = ["arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/${var.app_name}/*"]
  }
}

data "aws_iam_policy_document" "ecs_task_exec" {
  statement {
    sid    = "ECSExec"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ecs_task_cloudwatch" {
  statement {
    sid       = "CloudWatchMetrics"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ecs_task_efs" {
  statement {
    sid    = "EFSAccess"
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess"
    ]
    resources = [aws_efs_file_system.this.arn]
  }
}

# ECS Execution Role - IAM Policies
resource "aws_iam_policy" "ecs_execution_ssm" {
  name        = "${var.app_name}-${var.environment}-ecs-exec-ssm"
  description = "SSM parameter access for ECS execution role"
  policy      = data.aws_iam_policy_document.ecs_execution_ssm.json

  tags = local.default_tags
}

resource "aws_iam_policy" "ecs_execution_secrets" {
  name        = "${var.app_name}-${var.environment}-ecs-exec-secrets"
  description = "Secrets Manager access for ECS execution role"
  policy      = data.aws_iam_policy_document.ecs_execution_secrets.json

  tags = local.default_tags
}

resource "aws_iam_policy" "ecs_execution_kms" {
  name        = "${var.app_name}-${var.environment}-ecs-exec-kms"
  description = "KMS decrypt for ECS execution role"
  policy      = data.aws_iam_policy_document.ecs_execution_kms.json

  tags = local.default_tags
}

resource "aws_iam_policy" "ecs_execution_logs" {
  name        = "${var.app_name}-${var.environment}-ecs-exec-logs"
  description = "CloudWatch Logs access for ECS execution role"
  policy      = data.aws_iam_policy_document.ecs_execution_logs.json

  tags = local.default_tags
}

# ECS Task Role - IAM Policies
resource "aws_iam_policy" "ecs_task_ssm" {
  name        = "${var.app_name}-${var.environment}-ecs-task-ssm"
  description = "SSM parameter access for ECS task role"
  policy      = data.aws_iam_policy_document.ecs_task_ssm.json

  tags = local.default_tags
}

resource "aws_iam_policy" "ecs_task_exec" {
  name        = "${var.app_name}-${var.environment}-ecs-task-exec"
  description = "ECS Exec access for ECS task role"
  policy      = data.aws_iam_policy_document.ecs_task_exec.json

  tags = local.default_tags
}

resource "aws_iam_policy" "ecs_task_cloudwatch" {
  name        = "${var.app_name}-${var.environment}-ecs-task-cw"
  description = "CloudWatch metrics access for ECS task role"
  policy      = data.aws_iam_policy_document.ecs_task_cloudwatch.json

  tags = local.default_tags
}

resource "aws_iam_policy" "ecs_task_efs" {
  name        = "${var.app_name}-${var.environment}-ecs-task-efs"
  description = "EFS access for ECS task role"
  policy      = data.aws_iam_policy_document.ecs_task_efs.json

  tags = local.default_tags
}