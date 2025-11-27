# Logging (Auditing)
resource "aws_cloudwatch_log_group" "msk" {
  name              = "/aws/msk/${var.app_name}-cluster-logs"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.msk.arn

  tags = var.common_tags
}

# MSK Configuration (Governance)
resource "aws_msk_configuration" "this" {
  name           = "${var.app_name}-msk-config"
  kafka_versions = [var.kafka_version]

  server_properties = join("\n", [for k, v in var.server_properties : "${k} = ${v}"])
}

# MSK Cluster (The Core Infrastructure)
resource "aws_msk_cluster" "this" {
  cluster_name           = "${var.app_name}-msk-cluster"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes
  enhanced_monitoring    = "PER_TOPIC_PER_BROKER"

  broker_node_group_info {
    instance_type   = var.instance_type
    client_subnets  = var.private_subnets
    security_groups = [aws_security_group.msk.id]
    
    storage_info {
      ebs_storage_info {
        volume_size = var.ebs_volume_size
        
        dynamic "provisioned_throughput" {
          for_each = var.provisioned_throughput != null ? [1] : []
          content {
            enabled           = true
            volume_throughput = var.provisioned_throughput
          }
        }
      }
    }
  }


  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.msk.arn
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
    }
  }

  client_authentication {
    sasl {
      scram = true
      iam   = var.enable_iam
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.this.arn
    revision = aws_msk_configuration.this.latest_revision
  }

  tags = var.common_tags
}