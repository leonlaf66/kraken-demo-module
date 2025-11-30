# KMS Key Outputs
output "kms_key_mnpi_arn" {
  description = "KMS key ARN for MNPI data encryption"
  value       = aws_kms_key.mnpi.arn
}

output "kms_key_mnpi_id" {
  description = "KMS key ID for MNPI data encryption"
  value       = aws_kms_key.mnpi.key_id
}

output "kms_key_public_arn" {
  description = "KMS key ARN for Public data encryption"
  value       = aws_kms_key.public.arn
}

output "kms_key_public_id" {
  description = "KMS key ID for Public data encryption"
  value       = aws_kms_key.public.key_id
}

# S3 Bucket Outputs
# Raw Layer
output "bucket_raw_mnpi_arn" {
  description = "ARN of Raw MNPI bucket"
  value       = aws_s3_bucket.datalake["raw_mnpi"].arn
}

output "bucket_raw_mnpi_id" {
  description = "Name of Raw MNPI bucket"
  value       = aws_s3_bucket.datalake["raw_mnpi"].id
}

output "bucket_raw_public_arn" {
  description = "ARN of Raw Public bucket"
  value       = aws_s3_bucket.datalake["raw_public"].arn
}

output "bucket_raw_public_id" {
  description = "Name of Raw Public bucket"
  value       = aws_s3_bucket.datalake["raw_public"].id
}

# Curated Layer
output "bucket_curated_mnpi_arn" {
  description = "ARN of Curated MNPI bucket"
  value       = aws_s3_bucket.datalake["curated_mnpi"].arn
}

output "bucket_curated_mnpi_id" {
  description = "Name of Curated MNPI bucket"
  value       = aws_s3_bucket.datalake["curated_mnpi"].id
}

output "bucket_curated_public_arn" {
  description = "ARN of Curated Public bucket"
  value       = aws_s3_bucket.datalake["curated_public"].arn
}

output "bucket_curated_public_id" {
  description = "Name of Curated Public bucket"
  value       = aws_s3_bucket.datalake["curated_public"].id
}

# Analytics Layer
output "bucket_analytics_mnpi_arn" {
  description = "ARN of Analytics MNPI bucket"
  value       = aws_s3_bucket.datalake["analytics_mnpi"].arn
}

output "bucket_analytics_mnpi_id" {
  description = "Name of Analytics MNPI bucket"
  value       = aws_s3_bucket.datalake["analytics_mnpi"].id
}

output "bucket_analytics_public_arn" {
  description = "ARN of Analytics Public bucket"
  value       = aws_s3_bucket.datalake["analytics_public"].arn
}

output "bucket_analytics_public_id" {
  description = "Name of Analytics Public bucket"
  value       = aws_s3_bucket.datalake["analytics_public"].id
}

output "buckets" {
  description = "Map of all data lake buckets"
  value = {
    for k, v in aws_s3_bucket.datalake : k => {
      arn  = v.arn
      id   = v.id
      tier = local.buckets[k].tier
      sensitivity = local.buckets[k].sensitivity
    }
  }
}

output "mnpi_bucket_arns" {
  description = "List of all MNPI bucket ARNs"
  value       = [for k, v in local.mnpi_buckets : aws_s3_bucket.datalake[k].arn]
}

output "public_bucket_arns" {
  description = "List of all Public bucket ARNs"
  value       = [for k, v in local.public_buckets : aws_s3_bucket.datalake[k].arn]
}

# Glue Database Outputs
output "glue_database_raw_mnpi_name" {
  description = "Glue database for Raw MNPI data"
  value       = aws_glue_catalog_database.datalake["raw_mnpi"].name
}

output "glue_database_raw_public_name" {
  description = "Glue database for Raw Public data"
  value       = aws_glue_catalog_database.datalake["raw_public"].name
}

output "glue_database_curated_mnpi_name" {
  description = "Glue database for Curated MNPI data"
  value       = aws_glue_catalog_database.datalake["curated_mnpi"].name
}

output "glue_database_curated_public_name" {
  description = "Glue database for Curated Public data"
  value       = aws_glue_catalog_database.datalake["curated_public"].name
}

output "glue_database_analytics_mnpi_name" {
  description = "Glue database for Analytics MNPI data"
  value       = aws_glue_catalog_database.datalake["analytics_mnpi"].name
}

output "glue_database_analytics_public_name" {
  description = "Glue database for Analytics Public data"
  value       = aws_glue_catalog_database.datalake["analytics_public"].name
}

output "glue_databases" {
  description = "Map of all Glue databases"
  value = {
    for k, v in aws_glue_catalog_database.datalake : k => {
      name = v.name
      arn  = v.arn
    }
  }
}

# Audit & Logging Outputs
output "access_logs_bucket_id" {
  description = "S3 access logs bucket name"
  value       = aws_s3_bucket.access_logs.id
}

output "access_logs_bucket_arn" {
  description = "S3 access logs bucket ARN"
  value       = aws_s3_bucket.access_logs.arn
}

output "cloudtrail_bucket_id" {
  description = "CloudTrail logs bucket name"
  value       = aws_s3_bucket.cloudtrail.id
}

output "cloudtrail_bucket_arn" {
  description = "CloudTrail logs bucket ARN"
  value       = aws_s3_bucket.cloudtrail.arn
}

output "cloudtrail_name" {
  description = "CloudTrail trail name"
  value       = aws_cloudtrail.datalake.name
}

output "cloudtrail_arn" {
  description = "CloudTrail trail ARN"
  value       = aws_cloudtrail.datalake.arn
}