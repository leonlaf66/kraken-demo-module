resource "aws_security_group" "this" {
  name        = "${var.connector_name}-sg"
  description = "Security group for MSK Connector ${var.connector_name}"
  vpc_id      = var.vpc_id


  tags = var.common_tags
}

resource "aws_vpc_security_group_egress_rule" "connect_outbound" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic to MSK, S3, RDS"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}