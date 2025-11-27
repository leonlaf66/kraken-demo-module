variable "connector_name" {
  type = string
}

variable "kafkaconnect_version" {
  type    = string
  default = "2.7.1"
}

variable "connector_configuration" {
  type        = map(string)
  description = "The specific configuration properties for the connector (Debezium or S3 Sink)"
}

variable "msk_bootstrap_servers" {
  type = string
}

variable "msk_authentication_type" {
  type        = string
  default     = "NONE"
  description = "The type of client authentication used to connect to the Apache Kafka cluster. Valid values: IAM, NONE. For SCRAM/SASL, use NONE."
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID to create the connector security group in"
}

variable "custom_plugin_arn" {
  type = string
}

variable "custom_plugin_revision" {
  type = number
}


variable "custom_plugin_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket where custom plugins are stored (required for read access)"
}

variable "s3_sink_bucket_arn" {
  type        = string
  default     = null
  description = "ARN of the S3 bucket for Sink Connectors (optional, only needed for S3 Sink)"
}

variable "msk_kms_key_arn" {
  type        = string
  default     = null
  description = "ARN of the KMS key used by MSK cluster (optional)"
}

variable "s3_kms_key_arn" {
  type        = string
  default     = null
  description = "ARN of the KMS key used by S3 Sink bucket (optional)"
}

variable "log_retention_in_days" {
  type        = number
  default     = 7
  description = "Number of days to retain CloudWatch logs for the connector"
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

# Autoscaling defaults
variable "autoscaling_mcu_count" { default = 1 }
variable "autoscaling_min_worker_count" { default = 1 }
variable "autoscaling_max_worker_count" { default = 2 }
variable "autoscaling_scale_in_cpu" { default = 20 }
variable "autoscaling_scale_out_cpu" { default = 80 }