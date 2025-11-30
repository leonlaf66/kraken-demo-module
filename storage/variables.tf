# =============================================================================
# Core Variables
# =============================================================================

variable "app_name" {
  type        = string
  description = "Application name"
}

variable "env" {
  type        = string
  description = "Environment (dev, qa, prod)"

  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.env)
    error_message = "Environment must be one of: dev, qa, staging, prod."
  }
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}

# =============================================================================
# MNPI Security Configuration
# =============================================================================

variable "enable_mnpi_object_lock" {
  type        = bool
  description = "Enable S3 Object Lock for MNPI buckets (WORM compliance)"
  default     = false
}

variable "mnpi_object_lock_retention_days" {
  type        = number
  description = "Object Lock retention period in days (if enabled)"
  default     = 365
}

# =============================================================================
# Logging & Audit Configuration
# =============================================================================

variable "enable_access_logging" {
  type        = bool
  description = "Enable S3 access logging for all data lake buckets"
  default     = true
}

variable "access_log_retention_days" {
  type        = number
  description = "Days to retain access logs before transitioning to Glacier"
  default     = 365
}

variable "cloudtrail_retention_days" {
  type        = number
  description = "Days to retain CloudTrail logs before expiration"
  default     = 2555  # 7 years for compliance
}


