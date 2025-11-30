resource "aws_kms_key" "mnpi" {
  description             = "${var.app_name} MNPI Data Encryption Key - ${var.env}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = false

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },

      {
        Sid    = "AllowIAMPolicyControl"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = var.account_id
          }
        }
      },

      {
        Sid    = "AllowAWSServices"
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "glue.amazonaws.com",
            "athena.amazonaws.com"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = var.account_id
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.app_name}-mnpi-key"
    Sensitivity = "MNPI"
    Purpose     = "Data Lake Encryption"
  })
}

resource "aws_kms_alias" "mnpi" {
  name          = "alias/${var.app_name}-mnpi-${var.env}"
  target_key_id = aws_kms_key.mnpi.key_id
}

resource "aws_kms_key" "public" {
  description             = "${var.app_name} Public Data Encryption Key - ${var.env}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = false

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },

      {
        Sid    = "AllowAccountUsage"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = var.account_id
          }
        }
      },

      {
        Sid    = "AllowAWSServices"
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "glue.amazonaws.com",
            "athena.amazonaws.com"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = var.account_id
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.app_name}-public-key"
    Sensitivity = "Public"
    Purpose     = "Data Lake Encryption"
  })
}

resource "aws_kms_alias" "public" {
  name          = "alias/${var.app_name}-public-${var.env}"
  target_key_id = aws_kms_key.public.key_id
}
