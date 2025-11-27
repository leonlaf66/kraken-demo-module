resource "aws_security_group" "msk" {
  name        = "${var.app_name}-msk-sg"
  description = "Security group for MSK cluster"
  vpc_id      = var.vpc_id

  tags = var.common_tags
}


resource "aws_vpc_security_group_ingress_rule" "msk_scram" {
  security_group_id = aws_security_group.msk.id
  description       = "Allow SCRAM Auth Traffic (9096) from VPC"
  
  from_port   = 9096
  to_port     = 9096
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr
}

resource "aws_vpc_security_group_ingress_rule" "msk_iam" {
  count = var.enable_iam ? 1 : 0

  security_group_id = aws_security_group.msk.id
  description       = "Allow IAM Auth Traffic (9098) from VPC"
  
  from_port   = 9098
  to_port     = 9098
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "msk_outbound" {
  security_group_id = aws_security_group.msk.id
  description       = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}