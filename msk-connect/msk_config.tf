resource "aws_mskconnect_connector" "this" {
  name                 = var.connector_name
  kafkaconnect_version = var.kafkaconnect_version

  capacity {
    autoscaling {
      mcu_count        = var.autoscaling_mcu_count
      min_worker_count = var.autoscaling_min_worker_count
      max_worker_count = var.autoscaling_max_worker_count
      
      scale_in_policy {
        cpu_utilization_percentage = var.autoscaling_scale_in_cpu
      }
      scale_out_policy {
        cpu_utilization_percentage = var.autoscaling_scale_out_cpu
      }
    }
  }

  connector_configuration = var.connector_configuration

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = var.msk_bootstrap_servers
      vpc {
        security_groups = [aws_security_group.this.id]
        subnets         = var.subnet_ids
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = var.msk_authentication_type
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  plugin {
    custom_plugin {
      arn      = var.custom_plugin_arn
      revision = var.custom_plugin_revision
    }
  }

  service_execution_role_arn = aws_iam_role.msk_connect.arn
  
  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.this.name
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/msk-connect/${var.connector_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.common_tags
}