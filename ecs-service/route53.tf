resource "aws_route53_record" "alb" {
  for_each = local.services_with_route53

  zone_id = each.value.route53_zone_id
  name    = coalesce(each.value.route53_record_name, each.key)
  type    = "A"

  alias {
    name                   = aws_lb.this[each.key].dns_name
    zone_id                = aws_lb.this[each.key].zone_id
    evaluate_target_health = true
  }
}
locals {
  # Service DNS names from Route53 records
  service_dns_names = {
    for k, v in aws_route53_record.alb : k => v.fqdn
  }

  # ALB DNS names for all services with ALB
  service_alb_dns_names = {
    for k, v in aws_lb.this : k => v.dns_name
  }
}
