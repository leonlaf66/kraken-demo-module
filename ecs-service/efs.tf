# EFS File System
resource "aws_efs_file_system" "this" {
  creation_token   = "${var.app_name}-${var.environment}-efs"
  performance_mode = var.efs_performance_mode
  throughput_mode  = var.efs_throughput_mode
  encrypted        = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${var.app_name}-${var.environment}-efs"
    }
  )
}

# EFS Mount Targets (one per subnet)
resource "aws_efs_mount_target" "this" {
  for_each = toset(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

# EFS Access Points (one per service-volume combination)
resource "aws_efs_access_point" "this" {
  for_each = local.efs_access_points

  file_system_id = aws_efs_file_system.this.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/${each.value.service_name}/${each.value.volume_name}"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0755"
    }
  }

  tags = merge(
    local.default_tags,
    {
      Name    = "${var.app_name}-${var.environment}-${each.key}-ap"
      Service = each.value.service_name
      Volume  = each.value.volume_name
    }
  )
}

# EFS Backup Policy
resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = "ENABLED"
  }
}
