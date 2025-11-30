data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["kafkaconnect.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "msk_cluster" {
  statement {
    sid    = "MSKClusterConnect"
    effect = "Allow"
    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster"
    ]
    resources = [var.msk_cluster_arn]
  }
}

data "aws_iam_policy_document" "msk_write_topics" {
  count = var.connector_type == "source" && length(var.kafka_topics_write) > 0 ? 1 : 0

  statement {
    sid    = "MSKWriteTopics"
    effect = "Allow"
    actions = [
      "kafka-cluster:CreateTopic",
      "kafka-cluster:DescribeTopic",
      "kafka-cluster:WriteData"
    ]
    resources = [
      for topic in var.kafka_topics_write :
      "arn:aws:kafka:${var.region}:${var.account_id}:topic/${split("/", var.msk_cluster_arn)[1]}/*/${topic}"
    ]
  }
}

data "aws_iam_policy_document" "msk_read_topics" {
  count = var.connector_type == "sink" && length(var.kafka_topics_read) > 0 ? 1 : 0

  statement {
    sid    = "MSKReadTopics"
    effect = "Allow"
    actions = [
      "kafka-cluster:DescribeTopic",
      "kafka-cluster:ReadData"
    ]
    resources = [
      for topic in var.kafka_topics_read :
      "arn:aws:kafka:${var.region}:${var.account_id}:topic/${split("/", var.msk_cluster_arn)[1]}/*/${topic}"
    ]
  }

  statement {
    sid    = "MSKConsumerGroup"
    effect = "Allow"
    actions = [
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeGroup"
    ]
    resources = ["arn:aws:kafka:${var.region}:${var.account_id}:group/${split("/", var.msk_cluster_arn)[1]}/*/${var.connector_name}-*"]
  }
}

data "aws_iam_policy_document" "s3_plugin" {
  statement {
    sid    = "S3PluginAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      var.custom_plugin_bucket_arn,
      "${var.custom_plugin_bucket_arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "s3_sink" {
  count = var.connector_type == "sink" && var.s3_sink_bucket_arn != null ? 1 : 0

  statement {
    sid    = "S3SinkWrite"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload"
    ]
    resources = ["${var.s3_sink_bucket_arn}/*"]
  }

  statement {
    sid       = "S3SinkList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.s3_sink_bucket_arn]
  }
}

data "aws_iam_policy_document" "kms" {
  count = length(compact([var.msk_kms_key_arn, var.s3_kms_key_arn, var.secrets_kms_key_arn])) > 0 ? 1 : 0

  statement {
    sid    = "KMSAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = compact([
      var.msk_kms_key_arn,
      var.s3_kms_key_arn,
      var.secrets_kms_key_arn
    ])
  }
}

data "aws_iam_policy_document" "vpc" {
  statement {
    sid    = "VPCNetworkInterface"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/msk-connect/${var.connector_name}:*"]
  }

  statement {
    sid       = "CloudWatchLogsCreateGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/msk-connect/${var.connector_name}"]
  }
}

data "aws_iam_policy_document" "secrets_manager" {
  count = var.connector_type == "source" && var.rds_secret_arn != null ? 1 : 0

  statement {
    sid       = "SecretsManagerRDS"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.rds_secret_arn]
  }
}

###policy

resource "aws_iam_policy" "msk_cluster" {
  name        = "${var.connector_name}-msk-cluster"
  description = "MSK cluster access for ${var.connector_name}"
  policy      = data.aws_iam_policy_document.msk_cluster.json

  tags = var.common_tags
}

resource "aws_iam_policy" "msk_write_topics" {
  count = var.connector_type == "source" && length(var.kafka_topics_write) > 0 ? 1 : 0

  name        = "${var.connector_name}-msk-write"
  description = "MSK topic write access for ${var.connector_name}"
  policy      = data.aws_iam_policy_document.msk_write_topics[0].json

  tags = var.common_tags
}

resource "aws_iam_policy" "msk_read_topics" {
  count = var.connector_type == "sink" && length(var.kafka_topics_read) > 0 ? 1 : 0

  name        = "${var.connector_name}-msk-read"
  description = "MSK topic read access for ${var.connector_name}"
  policy      = data.aws_iam_policy_document.msk_read_topics[0].json

  tags = var.common_tags
}

resource "aws_iam_policy" "s3_plugin" {
  name        = "${var.connector_name}-s3-plugin"
  description = "S3 plugin access for ${var.connector_name}"
  policy      = data.aws_iam_policy_document.s3_plugin.json

  tags = var.common_tags
}

resource "aws_iam_policy" "s3_sink" {
  count = var.connector_type == "sink" && var.s3_sink_bucket_arn != null ? 1 : 0

  name        = "${var.connector_name}-s3-sink"
  description = "S3 sink bucket access for ${var.connector_name}"
  policy      = data.aws_iam_policy_document.s3_sink[0].json

  tags = var.common_tags
}

resource "aws_iam_policy" "kms" {
  count = length(compact([var.msk_kms_key_arn, var.s3_kms_key_arn, var.secrets_kms_key_arn])) > 0 ? 1 : 0

  name        = "${var.connector_name}-kms"
  description = "KMS access for ${var.connector_name}"
  policy      = data.aws_iam_policy_document.kms[0].json

  tags = var.common_tags
}

resource "aws_iam_policy" "vpc" {
  name        = "${var.connector_name}-vpc"
  description = "VPC network interface access for ${var.connector_name}"
  policy      = data.aws_iam_policy_document.vpc.json

  tags = var.common_tags
}

resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.connector_name}-cloudwatch"
  description = "CloudWatch Logs access for ${var.connector_name}"
  policy      = data.aws_iam_policy_document.cloudwatch_logs.json

  tags = var.common_tags
}

resource "aws_iam_policy" "secrets_manager" {
  count = var.connector_type == "source" && var.rds_secret_arn != null ? 1 : 0

  name        = "${var.connector_name}-secrets"
  description = "Secrets Manager access for ${var.connector_name}"
  policy      = data.aws_iam_policy_document.secrets_manager[0].json

  tags = var.common_tags
}