resource "random_password" "master" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret" "master" {
  name                    = "${var.app_name}-rds-master-creds-${var.env}"
  description             = "Master DB credentials for ${var.app_name} RDS"
  recovery_window_in_days = 7
  
  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "master" {
  secret_id     = aws_secretsmanager_secret.master.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.master.result
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = 5432
    dbname   = "kraken_db"
  })
}