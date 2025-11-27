output "connector_arn" {
  value = aws_mskconnect_connector.this.arn
}

output "connector_version" {
  value = aws_mskconnect_connector.this.version
}

output "security_group_id" {
  description = "The ID of the security group created for this connector"
  value       = aws_security_group.this.id
}

output "iam_role_arn" {
  description = "The ARN of the IAM Role created for this connector"
  value       = aws_iam_role.msk_connect.arn
}