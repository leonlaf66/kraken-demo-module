# =============================================================================
# Assume Role Policy
# =============================================================================

data "aws_iam_policy_document" "assume_role" {
  for_each = var.user_groups

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }

    dynamic "condition" {
      for_each = each.value.mfa_required ? [1] : []
      content {
        test     = "Bool"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["true"]
      }
    }
  }
}

# =============================================================================
# Athena Workgroup Policy
# =============================================================================

data "aws_iam_policy_document" "athena_workgroup" {
  for_each = var.user_groups

  statement {
    sid    = "AthenaWorkgroupAccess"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup",
      "athena:BatchGetQueryExecution",
      "athena:ListQueryExecutions"
    ]
    resources = [
      aws_athena_workgroup.this[each.key].arn
    ]
  }

  statement {
    sid    = "AthenaDataCatalogAccess"
    effect = "Allow"
    actions = [
      "athena:GetDataCatalog",
      "athena:ListDataCatalogs"
    ]
    resources = [
      "arn:aws:athena:${var.region}:${var.account_id}:datacatalog/AwsDataCatalog"
    ]
  }
}

resource "aws_iam_policy" "athena_workgroup" {
  for_each = var.user_groups

  name        = "${var.app_name}-${replace(each.key, "_", "-")}-athena-${var.env}"
  description = "Athena workgroup access for ${each.key}"
  policy      = data.aws_iam_policy_document.athena_workgroup[each.key].json

  tags = var.common_tags
}

# =============================================================================
# Glue Catalog Policy
# =============================================================================

data "aws_iam_policy_document" "glue_catalog" {
  for_each = var.user_groups

  statement {
    sid    = "GlueCatalogAccess"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition"
    ]
    resources = concat(
      # Catalog
      ["arn:aws:glue:${var.region}:${var.account_id}:catalog"],
      # Databases
      [for db in compact(local.user_group_databases[each.key]) : "arn:aws:glue:${var.region}:${var.account_id}:database/${db}"],
      # Tables in those databases
      [for db in compact(local.user_group_databases[each.key]) : "arn:aws:glue:${var.region}:${var.account_id}:table/${db}/*"]
    )
  }

  # Data Engineers can manage tables
  dynamic "statement" {
    for_each = each.value.can_manage_tables ? [1] : []
    content {
      sid    = "GlueTableManagement"
      effect = "Allow"
      actions = [
        "glue:CreateTable",
        "glue:UpdateTable",
        "glue:DeleteTable",
        "glue:BatchCreatePartition",
        "glue:BatchDeletePartition",
        "glue:UpdatePartition"
      ]
      resources = concat(
        [for db in compact(local.user_group_databases[each.key]) : "arn:aws:glue:${var.region}:${var.account_id}:database/${db}"],
        [for db in compact(local.user_group_databases[each.key]) : "arn:aws:glue:${var.region}:${var.account_id}:table/${db}/*"]
      )
    }
  }
}

resource "aws_iam_policy" "glue_catalog" {
  for_each = var.user_groups

  name        = "${var.app_name}-${replace(each.key, "_", "-")}-glue-${var.env}"
  description = "Glue catalog access for ${each.key}"
  policy      = data.aws_iam_policy_document.glue_catalog[each.key].json

  tags = var.common_tags
}

# =============================================================================
# S3 Data Lake Policy
# =============================================================================

data "aws_iam_policy_document" "s3_data_lake" {
  for_each = var.user_groups

  statement {
    sid    = "S3BucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = compact(local.user_group_buckets[each.key])
  }

  statement {
    sid    = "S3ObjectRead"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [for bucket in compact(local.user_group_buckets[each.key]) : "${bucket}/*"]
  }

  # Data Engineers can write to buckets
  dynamic "statement" {
    for_each = each.value.can_manage_tables ? [1] : []
    content {
      sid    = "S3ObjectWrite"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:DeleteObject"
      ]
      resources = [for bucket in compact(local.user_group_buckets[each.key]) : "${bucket}/*"]
    }
  }
}

resource "aws_iam_policy" "s3_data_lake" {
  for_each = var.user_groups

  name        = "${var.app_name}-${replace(each.key, "_", "-")}-s3-datalake-${var.env}"
  description = "S3 data lake access for ${each.key}"
  policy      = data.aws_iam_policy_document.s3_data_lake[each.key].json

  tags = var.common_tags
}

# =============================================================================
# S3 Query Results Policy
# =============================================================================

data "aws_iam_policy_document" "s3_query_results" {
  for_each = var.user_groups

  statement {
    sid    = "S3QueryResultsBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.athena_results.arn]
  }

  statement {
    sid    = "S3QueryResultsReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload"
    ]
    resources = ["${aws_s3_bucket.athena_results.arn}/${each.key}/*"]
  }
}

resource "aws_iam_policy" "s3_query_results" {
  for_each = var.user_groups

  name        = "${var.app_name}-${replace(each.key, "_", "-")}-s3-results-${var.env}"
  description = "Athena query results access for ${each.key}"
  policy      = data.aws_iam_policy_document.s3_query_results[each.key].json

  tags = var.common_tags
}

# =============================================================================
# KMS Policy
# =============================================================================

data "aws_iam_policy_document" "kms" {
  for_each = var.user_groups

  statement {
    sid    = "KMSDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = local.user_group_kms_keys[each.key]
  }
}

resource "aws_iam_policy" "kms" {
  for_each = var.user_groups

  name        = "${var.app_name}-${replace(each.key, "_", "-")}-kms-${var.env}"
  description = "KMS access for ${each.key}"
  policy      = data.aws_iam_policy_document.kms[each.key].json

  tags = var.common_tags
}
