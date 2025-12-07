resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.app_name}-access-logs-${var.account_id}-${var.env}"

  tags = merge(var.common_tags, {
    Name    = "${var.app_name}-access-logs"
    Purpose = "S3 Access Logs"
  })
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "access-logs-lifecycle"
    status = "Enabled"

    filter {}

    transition {
      days          = var.access_log_retention_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.access_log_retention_days * 2
    }
  }
}

resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ServerAccessLogsPolicy"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.access_logs.arn}/*"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::${var.app_name}-*-${var.account_id}-${var.env}"
          }
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
        }
      }
    ]
  })
}

# Data Lake Buckets
resource "aws_s3_bucket" "datalake" {
  for_each = local.buckets

  bucket = "${var.app_name}-${replace(each.key, "_", "-")}-${var.account_id}-${var.env}"

  dynamic "object_lock_configuration" {
    for_each = each.value.sensitivity == "mnpi" && var.enable_mnpi_object_lock ? [1] : []
    content {
      object_lock_enabled = "Enabled"
    }
  }

  tags = merge(var.common_tags, {
    Name        = "${var.app_name}-${replace(each.key, "_", "-")}"
    Tier        = title(each.value.tier)
    Sensitivity = upper(each.value.sensitivity)
    DataLake    = "true"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "datalake" {
  for_each = local.buckets

  bucket = aws_s3_bucket.datalake[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = each.value.sensitivity == "mnpi" ? aws_kms_key.mnpi.arn : aws_kms_key.public.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "datalake" {
  for_each = local.buckets

  bucket = aws_s3_bucket.datalake[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "datalake" {
  for_each = local.buckets

  bucket = aws_s3_bucket.datalake[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "datalake" {
  for_each = var.enable_access_logging ? local.buckets : {}

  bucket = aws_s3_bucket.datalake[each.key].id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "${each.key}/"
}


resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  for_each = local.buckets

  bucket = aws_s3_bucket.datalake[each.key].id

  rule {
    id     = "standard-lifecycle"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "cleanup-noncurrent"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_object_lock_configuration" "mnpi" {
  for_each = var.enable_mnpi_object_lock ? local.mnpi_buckets : {}

  bucket = aws_s3_bucket.datalake[each.key].id

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = var.mnpi_object_lock_retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.datalake]
}
