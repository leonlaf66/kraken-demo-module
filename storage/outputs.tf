output "kms_key_mnpi_arn" {
  value = aws_kms_key.mnpi.arn
  description = "The ARN of the KMS Key used for MNPI data"
}

output "kms_key_public_arn" {
  value = aws_kms_key.public.arn
  description = "The ARN of the KMS Key used for Public data"
}

output "bucket_raw_mnpi_id" {
  value = aws_s3_bucket.raw_mnpi.id
  description = "The name of the Raw MNPI S3 Bucket"
}

output "bucket_raw_mnpi_arn" {
  value = aws_s3_bucket.raw_mnpi.arn
  description = "The ARN of the Raw MNPI S3 Bucket"
}

output "bucket_raw_public_id" {
  value = aws_s3_bucket.raw_public.id
  description = "The name of the Raw Public S3 Bucket"
}

output "bucket_raw_public_arn" {
  value = aws_s3_bucket.raw_public.arn
  description = "The ARN of the Raw Public S3 Bucket"
}

output "glue_database_mnpi_name" {
  value = aws_glue_catalog_database.raw_mnpi.name
}

output "glue_database_public_name" {
  value = aws_glue_catalog_database.raw_public.name
}