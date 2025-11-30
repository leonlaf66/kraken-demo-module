# Core Configuration
variable "app_name" {
  type        = string
  description = "Application name for resource naming"
}

variable "env" {
  type        = string
  description = "Environment (dev, qa, prod)"
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
  default     = {}
  description = "Common tags for all resources"
}

# S3 Buckets - Data Lake (organized by layer and sensitivity)
variable "buckets" {
  type = object({
    raw_mnpi         = string
    raw_public       = string
    curated_mnpi     = string
    curated_public   = string
    analytics_mnpi   = string
    analytics_public = string
  })
  description = "ARNs of all data lake buckets"
}

# KMS Keys
variable "kms_keys" {
  type = object({
    mnpi   = string
    public = string
  })
  description = "KMS key ARNs for MNPI and Public data"
}

# Glue Databases
variable "glue_databases" {
  type = object({
    raw_mnpi         = string
    raw_public       = string
    curated_mnpi     = string
    curated_public   = string
    analytics_mnpi   = string
    analytics_public = string
  })
  description = "Glue database names for all layers"
}

# User Groups Configuration
variable "user_groups" {
  type = map(object({
    description            = string
    mnpi_access            = bool
    layers                 = list(string)
    mfa_required           = bool
    bytes_limit_multiplier = optional(number, 1)
    can_manage_tables      = optional(bool, false)
  }))

  default = {
    finance_analysts = {
      description  = "Finance Analysts - Analytics layer (MNPI + Public)"
      mnpi_access  = true
      layers       = ["analytics"]
      mfa_required = true
    }
    data_analysts = {
      description  = "Data Analysts - Analytics layer (Public only)"
      mnpi_access  = false
      layers       = ["analytics"]
      mfa_required = false
    }
    data_engineers = {
      description            = "Data Engineers - Full access to all layers"
      mnpi_access            = true
      layers                 = ["raw", "curated", "analytics"]
      mfa_required           = true
      bytes_limit_multiplier = 2
      can_manage_tables      = true
    }
  }

  description = "User group configurations for Athena access"
}

# Athena Configuration
variable "athena_bytes_scanned_cutoff" {
  type        = number
  default     = 10737418240 # 10 GB
  description = "Base maximum bytes scanned per query"
}

variable "query_result_retention_days" {
  type        = number
  default     = 30
  description = "Days to retain Athena query results"
}
