variable "app_name" {
  type        = string
  description = "The name of the application or service"
}

variable "env" {
  type        = string
  description = "The deployment environment (e.g., 'dev', 'qa', 'prod')"
}

variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Common tags to apply to resources"
}

# --- Network ---
variable "vpc_id" {
  type        = string
  description = "The VPC ID where the RDS instance will be deployed"
}

variable "db_subnet_group_name" {
  type        = string
  description = "The name of the DB subnet group to use"
}

variable "allowed_ingress_cidrs" {
  type        = list(string)
  default     = []
  description = "List of CIDR blocks allowed to access the database (e.g., VPC CIDR)"
}

# --- Database Config ---
variable "db_engine_version" {
  type        = string
  default     = "14.7"
  description = "PostgreSQL engine version"
}

variable "db_instance_class" {
  type        = string
  default     = "db.t3.medium"
  description = "The instance type of the RDS instance"
}

variable "db_allocated_storage" {
  type        = number
  default     = 20
  description = "The allocated storage in gigabytes"
}

variable "db_max_allocated_storage" {
  type        = number
  default     = 100
  description = "The upper limit to which Amazon RDS can automatically scale the storage of the DB instance"
}

variable "db_storage_type" {
  type        = string
  default     = "gp3"
  description = "The storage type (gp2, gp3, io1)"
}

variable "db_parameter_group_family" {
  type        = string
  default     = "postgres14"
  description = "The family of the DB parameter group"
}

variable "db_multi_az" {
  type        = bool
  default     = false
  description = "Specifies if the RDS instance is multi-AZ"
}

# --- Credentials ---
variable "db_username" {
  type        = string
  description = "Username for the master DB user"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Password for the master DB user"
}

# --- Maintenance ---
variable "skip_final_snapshot" {
  type        = bool
  default     = true
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted"
}

variable "backup_retention_period" {
  type        = number
  default     = 7
  description = "The days to retain backups for"
}

variable "deletion_protection" {
  type        = bool
  default     = false
  description = "If the DB instance should have deletion protection enabled"
}