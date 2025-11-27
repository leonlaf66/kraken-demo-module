data "aws_msk_broker_nodes" "nodes" {
  cluster_arn = aws_msk_cluster.this.arn
}

resource "aws_lb" "msk_nlb" {
  name                             = "${var.app_name}-${var.env}-msk-nlb"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = var.private_subnets
  enable_cross_zone_load_balancing = true
  security_groups                  = [aws_security_group.msk.id] 

  tags = merge(var.common_tags, { Name = "${var.app_name}-${var.env}-msk-nlb" })
}

resource "aws_lb_target_group" "msk_tg_scram" {
  name        = "${var.app_name}-${var.env}-msk-scram-tg"
  port        = 9096
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    protocol = "TCP"
    port     = 9096
  }
  tags = var.common_tags
}

resource "aws_lb_target_group_attachment" "brokers_scram" {
  for_each = {
    for node in data.aws_msk_broker_nodes.nodes.node_info_list :
    node.node_id => node.client_vpc_ip_address
  }
  target_group_arn = aws_lb_target_group.msk_tg_scram.arn
  target_id        = each.value
  port             = 9096
}

resource "aws_lb_listener" "msk_scram" {
  load_balancer_arn = aws_lb.msk_nlb.arn
  port              = 9096
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.msk_tg_scram.arn
  }
}