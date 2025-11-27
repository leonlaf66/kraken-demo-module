resource "aws_security_group" "rds" {
  name        = "${var.app_name}-rds-sg-${var.env}"
  description = "Security group for RDS Source DB"
  vpc_id      = var.vpc_id

  tags = var.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "rds_ingress" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.rds.id
  description       = "Allow Postgres access from specific CIDR"
  
  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
  cidr_ipv4   = each.value
}