resource "aws_iam_role" "msk_connect" {
  name = "${var.connector_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "kafkaconnect.amazonaws.com"
      }
    }]
  })
  
  tags = var.common_tags
}

resource "aws_iam_role_policy" "msk_connect" {
  name = "${var.connector_name}-policy"
  role = aws_iam_role.msk_connect.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MSKClusterAccess"
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:CreateTopic",
          "kafka-cluster:WriteData",
          "kafka-cluster:ReadData"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:AbortMultipartUpload"
        ]
        Resource = concat(
          [var.custom_plugin_bucket_arn, "${var.custom_plugin_bucket_arn}/*"],
          
          var.s3_sink_bucket_arn != null ? [var.s3_sink_bucket_arn, "${var.s3_sink_bucket_arn}/*"] : []
        )
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = concat(
          var.msk_kms_key_arn != null ? [var.msk_kms_key_arn] : [],
          var.s3_kms_key_arn != null ? [var.s3_kms_key_arn] : []
        )
      },
      {
        Sid    = "VPCAccess"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVpcs",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "LoggingAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecretsAccess"
        Effect = "Allow"
        Action = "secretsmanager:GetSecretValue"
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:AmazonMSK_*",
          "arn:aws:secretsmanager:*:*:secret:${var.connector_name}*"
        ]
      }
    ]
  })
}