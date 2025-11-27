variable "app_name" {
  type        = string
  description = "The name of the application or service, used for naming resources (e.g., 'kraken-data-platform')"
}

variable "env" {
  type        = string
  description = "The deployment environment (e.g., 'dev', 'qa', 'prod')"
}

variable "region" {
  type        = string
  description = "The AWS region where resources will be deployed (e.g., 'us-east-1')"
}

variable "account_id" {
  type        = string
  description = "The AWS Account ID where resources will be provisioned"
}

variable "common_tags" {
  type        = map(string)
  description = "A map of common tags to apply to all resources for governance and cost tracking"
}

# Network
variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the MSK cluster will be deployed"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block of the VPC, used for security group ingress rules"
}

variable "private_subnets" {
  type        = list(string)
  description = "A list of private subnet IDs for deploying MSK brokers and the NLB"
}

variable "private_hosted_zone_id" {
  type        = string
  default     = ""
  description = "Optional: The Route53 Private Hosted Zone ID for creating the stable bootstrap alias record"
}

# MSK Config
variable "kafka_version" {
  type        = string
  default     = "3.5.1"
  description = "The Apache Kafka version to use for the MSK cluster"
}

variable "number_of_broker_nodes" {
  type        = number
  default     = 3
  description = "The number of broker nodes in the MSK cluster (should be a multiple of the number of AZs)"
}

variable "instance_type" {
  type        = string
  default     = "kafka.m5.large"
  description = "The EC2 instance type for the MSK brokers"
}

variable "ebs_volume_size" {
  type        = number
  default     = 1000
  description = "The size in GiB of the EBS volume for each broker node"
}

variable "enable_iam" {
  type        = bool
  default     = false
  description = "Enable IAM authentication mechanism (Highly recommended for AWS service integration like MSK Connect)"
}

variable "scram_users" {
  type        = set(string)
  default     = ["admin"]
  description = "List of SCRAM usernames to create secrets for (e.g. ['admin', 'mnpi_reader']) if SCRAM is enabled"
}

variable "provisioned_throughput" {
  type        = number
  default     = null
  description = "Optional: Provisioned throughput in MiB/s for gp3 volumes (e.g., 250). Leave null for standard throughput."
}

variable "server_properties" {
  description = "Map of Kafka server.properties to configure the cluster (e.g., auto.create.topics.enable, log.retention.ms)"
  type        = map(string)
  default = {
    "auto.create.topics.enable"  = "false"
    "delete.topic.enable"        = "true"
    "default.replication.factor" = "3"
    "min.insync.replicas"        = "2"
    "num.io.threads"             = "8"
    "num.network.threads"        = "5"
    "num.partitions"             = "1"
    "num.replica.fetchers"       = "2"
    "log.retention.ms"           = "604800000"
  }
}