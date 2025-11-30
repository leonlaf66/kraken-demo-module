variable "app_name" {
  type        = string
  description = "The name of the application or service"
}

variable "env" {
  type        = string
  description = "The deployment environment (e.g., 'dev', 'qa', 'prod')"
}

variable "region" {
  type        = string
  description = "The AWS region"
}

variable "account_id" {
  type        = string
  description = "The AWS Account ID"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags for all resources"
}

# FIX: Removed unused audit_bucket_name variable
# The audit bucket is created internally by the module in cloud_trail.tf
# as aws_s3_bucket.audit with naming convention: ${var.app_name}-cloudtrail-logs-${var.account_id}-${var.env}
