resource "aws_iam_role" "msk_connect" {
  name               = "${var.connector_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "msk_cluster" {
  role       = aws_iam_role.msk_connect.name
  policy_arn = aws_iam_policy.msk_cluster.arn
}

resource "aws_iam_role_policy_attachment" "msk_write_topics" {
  count = var.connector_type == "source" && length(var.kafka_topics_write) > 0 ? 1 : 0

  role       = aws_iam_role.msk_connect.name
  policy_arn = aws_iam_policy.msk_write_topics[0].arn
}

resource "aws_iam_role_policy_attachment" "msk_read_topics" {
  count = var.connector_type == "sink" && length(var.kafka_topics_read) > 0 ? 1 : 0

  role       = aws_iam_role.msk_connect.name
  policy_arn = aws_iam_policy.msk_read_topics[0].arn
}

resource "aws_iam_role_policy_attachment" "s3_plugin" {
  role       = aws_iam_role.msk_connect.name
  policy_arn = aws_iam_policy.s3_plugin.arn
}

resource "aws_iam_role_policy_attachment" "s3_sink" {
  count = var.connector_type == "sink" && var.s3_sink_bucket_arn != null ? 1 : 0

  role       = aws_iam_role.msk_connect.name
  policy_arn = aws_iam_policy.s3_sink[0].arn
}

resource "aws_iam_role_policy_attachment" "kms" {
  count = length(compact([var.msk_kms_key_arn, var.s3_kms_key_arn, var.secrets_kms_key_arn])) > 0 ? 1 : 0

  role       = aws_iam_role.msk_connect.name
  policy_arn = aws_iam_policy.kms[0].arn
}

resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.msk_connect.name
  policy_arn = aws_iam_policy.vpc.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.msk_connect.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

resource "aws_iam_role_policy_attachment" "secrets_manager" {
  count = var.connector_type == "source" && var.rds_secret_arn != null ? 1 : 0

  role       = aws_iam_role.msk_connect.name
  policy_arn = aws_iam_policy.secrets_manager[0].arn
}
