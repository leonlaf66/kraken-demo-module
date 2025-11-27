resource "random_password" "scram_password" {
  for_each = var.scram_users
  length   = 16
  special  = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret" "scram_secret" {
  for_each                = var.scram_users
  name                    = "AmazonMSK_${var.app_name}-${var.env}_${each.key}"
  description             = "SCRAM credentials for user ${each.key}"
  kms_key_id              = aws_kms_key.msk.id
  recovery_window_in_days = 0
  
  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "scram_secret_val" {
  for_each      = var.scram_users
  secret_id     = aws_secretsmanager_secret.scram_secret[each.key].id
  secret_string = jsonencode({
    username = each.key
    password = random_password.scram_password[each.key].result
  })
}

resource "aws_secretsmanager_secret_policy" "scram_policy" {
  for_each   = var.scram_users
  secret_arn = aws_secretsmanager_secret.scram_secret[each.key].arn
  policy     = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AWSKafkaResourcePolicy"
      Effect = "Allow"
      Principal = { Service = "kafka.amazonaws.com" }
      Action   = "secretsmanager:getSecretValue"
      Resource = aws_secretsmanager_secret.scram_secret[each.key].arn
    }]
  })
}
