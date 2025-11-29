output "cluster_arn" {
  description = "ARN of the MSK cluster"
  value       = aws_msk_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the MSK cluster"
  value       = aws_msk_cluster.this.cluster_name
}

output "bootstrap_brokers_sasl_scram" {
  description = "Standard AWS MSK Endpoint (SCRAM)"
  value       = aws_msk_cluster.this.bootstrap_brokers_sasl_scram
}

output "bootstrap_brokers_sasl_iam" {
  description = "Standard AWS MSK Endpoint (IAM) - Optional"
  value       = var.enable_iam ? aws_msk_cluster.this.bootstrap_brokers_sasl_iam : null
}

output "bootstrap_brokers_nlb" {
  description = "Stable NLB Endpoint (kafka-bootstrap.internal:9096)"
  value       = var.private_hosted_zone_id != "" ? "kafka-bootstrap.${var.app_name}.internal:9096" : "${aws_lb.msk_nlb.dns_name}:9096"
}

output "nlb_dns_name" {
  description = "DNS name of the NLB"
  value       = aws_lb.msk_nlb.dns_name
}

output "route53_dns_name" {
  description = "Route53 DNS name for MSK bootstrap (null if not configured)"
  value       = var.private_hosted_zone_id != "" ? "kafka-bootstrap.${var.app_name}.internal" : null
}

output "security_group_id" {
  description = "Security group ID for MSK cluster"
  value       = aws_security_group.msk.id
}

output "kms_key_arn" {
  description = "KMS key ARN for MSK cluster encryption"
  value       = aws_kms_key.msk.arn
}

output "scram_secret_names" {
  description = "Map of SCRAM user names to their Secrets Manager secret names"
  value = {
    for user in var.scram_users : user => "AmazonMSK_${var.app_name}_${var.env}_${user}"
  }
}
