resource "aws_db_parameter_group" "cdc" {
  name   = "${var.app_name}-pg-cdc-${var.env}"
  family = var.db_parameter_group_family

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }
  
  parameter {
    name  = "wal_sender_timeout"
    value = "0"
  }

  tags = var.common_tags
}

resource "aws_db_instance" "this" {
  identifier = "${var.app_name}-source-db-${var.env}"
  
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class
  
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  
  username = var.db_username
  password = random_password.master.result

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.cdc.name
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = "${var.app_name}-source-db-${var.env}-final"
  backup_retention_period   = var.backup_retention_period
  deletion_protection       = var.deletion_protection
  
  tags = var.common_tags
}