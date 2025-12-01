resource "aws_route53_record" "bootstrap" {
  zone_id = var.private_hosted_zone_id
  name    = "kafka-bootstrap" 
  type    = "A"

  alias {
    name                   = aws_lb.msk_nlb.dns_name
    zone_id                = aws_lb.msk_nlb.zone_id
    evaluate_target_health = true
  }
}
