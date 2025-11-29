# =============================================================================
# KMS Keys Outputs
# =============================================================================
output "kms_key_mnpi_arn" {
  description = "The ARN of the KMS Key used for MNPI data"
  value       = aws_kms_key.mnpi.arn
}

output "kms_key_public_arn" {
  description = "The ARN of the KMS Key used for Public data"
  value       = aws_kms_key.public.arn
}

output "kms_key_mnpi_id" {
  description = "The ID of the KMS Key used for MNPI data"
  value       = aws_kms_key.mnpi.key_id
}

output "kms_key_public_id" {
  description = "The ID of the KMS Key used for Public data"
  value       = aws_kms_key.public.key_id
}

# =============================================================================
# S3 Buckets Outputs - Raw Layer
# =============================================================================
output "bucket_raw_mnpi_arn" {
  description = "ARN of the Raw MNPI S3 bucket"
  value       = aws_s3_bucket.raw_mnpi.arn
}

output "bucket_raw_mnpi_id" {
  description = "Name of the Raw MNPI S3 bucket"
  value       = aws_s3_bucket.raw_mnpi.id
}

output "bucket_raw_public_arn" {
  description = "ARN of the Raw Public S3 bucket"
  value       = aws_s3_bucket.raw_public.arn
}

output "bucket_raw_public_id" {
  description = "Name of the Raw Public S3 bucket"
  value       = aws_s3_bucket.raw_public.id
}

# =============================================================================
# S3 Buckets Outputs - Curated Layer
# =============================================================================
output "bucket_curated_mnpi_arn" {
  description = "ARN of the Curated MNPI S3 bucket"
  value       = aws_s3_bucket.curated_mnpi.arn
}

output "bucket_curated_mnpi_id" {
  description = "Name of the Curated MNPI S3 bucket"
  value       = aws_s3_bucket.curated_mnpi.id
}

output "bucket_curated_public_arn" {
  description = "ARN of the Curated Public S3 bucket"
  value       = aws_s3_bucket.curated_public.arn
}

output "bucket_curated_public_id" {
  description = "Name of the Curated Public S3 bucket"
  value       = aws_s3_bucket.curated_public.id
}

# =============================================================================
# S3 Buckets Outputs - Analytics Layer
# =============================================================================
output "bucket_analytics_mnpi_arn" {
  description = "ARN of the Analytics MNPI S3 bucket"
  value       = aws_s3_bucket.analytics_mnpi.arn
}

output "bucket_analytics_mnpi_id" {
  description = "Name of the Analytics MNPI S3 bucket"
  value       = aws_s3_bucket.analytics_mnpi.id
}

output "bucket_analytics_public_arn" {
  description = "ARN of the Analytics Public S3 bucket"
  value       = aws_s3_bucket.analytics_public.arn
}

output "bucket_analytics_public_id" {
  description = "Name of the Analytics Public S3 bucket"
  value       = aws_s3_bucket.analytics_public.id
}

# =============================================================================
# Glue Catalog Databases Outputs - Raw Layer
# =============================================================================
output "glue_database_raw_mnpi_name" {
  description = "Name of the Glue catalog database for Raw MNPI data"
  value       = aws_glue_catalog_database.raw_mnpi.name
}

output "glue_database_raw_public_name" {
  description = "Name of the Glue catalog database for Raw Public data"
  value       = aws_glue_catalog_database.raw_public.name
}

# =============================================================================
# Glue Catalog Databases Outputs - Curated Layer
# =============================================================================
output "glue_database_curated_mnpi_name" {
  description = "Name of the Glue catalog database for Curated MNPI data"
  value       = aws_glue_catalog_database.curated_mnpi.name
}

output "glue_database_curated_public_name" {
  description = "Name of the Glue catalog database for Curated Public data"
  value       = aws_glue_catalog_database.curated_public.name
}

# =============================================================================
# Glue Catalog Databases Outputs - Analytics Layer
# =============================================================================
output "glue_database_analytics_mnpi_name" {
  description = "Name of the Glue catalog database for Analytics MNPI data"
  value       = aws_glue_catalog_database.analytics_mnpi.name
}

output "glue_database_analytics_public_name" {
  description = "Name of the Glue catalog database for Analytics Public data"
  value       = aws_glue_catalog_database.analytics_public.name
}

# =============================================================================
# CloudTrail & Audit Outputs
# =============================================================================
output "cloudtrail_name" {
  description = "Name of the CloudTrail trail for audit logging"
  value       = aws_cloudtrail.datalake_audit.name
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail for audit logging"
  value       = aws_cloudtrail.datalake_audit.arn
}

output "audit_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail audit logs"
  value       = aws_s3_bucket.audit.id
}

output "audit_bucket_arn" {
  description = "ARN of the S3 bucket storing CloudTrail audit logs"
  value       = aws_s3_bucket.audit.arn
}
