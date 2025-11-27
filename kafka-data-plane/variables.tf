variable "msk_cluster_arn" {
  type        = string
  description = "ARN of the MSK cluster to associate SCRAM secrets with"
}

variable "msk_cluster_name" {
  type        = string
  description = "Name of the MSK cluster (used for secret naming)"
}

variable "kms_key_id" {
  type        = string
  description = "KMS Key ID to encrypt Secrets Manager secrets"
}

variable "common_tags" {
  type        = map(string)
  default     = {}
}

# Topics Configuration
variable "topics" {
  description = "List of Kafka topics to create"
  type = list(object({
    name               = string
    replication_factor = number
    partitions         = number
    config             = map(string)
  }))
  default = []
}

# ACLs Configuration (Consolidated)
variable "user_acls" {
  description = "Map of SCRAM usernames to their list of ACL permissions. The Key is the username."
  type = map(list(object({
    resource_name   = string
    resource_type   = string           # "Topic", "Group", "Cluster"
    operation       = string           # "Read", "Write", "All"
    permission_type = optional(string) # "Allow" (default) or "Deny"
    host            = optional(string) # "*" (default)
  })))
  default = {}
}