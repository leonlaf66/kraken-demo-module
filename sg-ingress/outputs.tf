output "ingress_rule_ids" {
  description = "Map of rule names to their ingress rule IDs"
  value = { for k, v in aws_vpc_security_group_ingress_rule.this : k => v.id }
}

output "ingress_rule_arns" {
  description = "Map of rule names to their ingress rule ARNs"
  value = { for k, v in aws_vpc_security_group_ingress_rule.this : k => v.arn }
}

output "rule_count" {
  description = "Total number of ingress rules created"
  value       = length(aws_vpc_security_group_ingress_rule.this)
}