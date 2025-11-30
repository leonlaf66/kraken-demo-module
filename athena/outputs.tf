output "workgroups" {
  description = "Map of workgroup names to their ARNs"
  value = {
    for k, v in aws_athena_workgroup.this : k => {
      name = v.name
      arn  = v.arn
    }
  }
}

output "roles" {
  description = "Map of role names to their ARNs"
  value = {
    for k, v in aws_iam_role.this : k => {
      name = v.name
      arn  = v.arn
    }
  }
}

output "query_results_bucket" {
  description = "Athena query results bucket"
  value = {
    name = aws_s3_bucket.athena_results.id
    arn  = aws_s3_bucket.athena_results.arn
  }
}

output "access_matrix" {
  description = "Summary of access permissions by user group"
  value = {
    for k, v in var.user_groups : k => {
      role_arn    = aws_iam_role.this[k].arn
      workgroup   = aws_athena_workgroup.this[k].name
      mnpi_access = v.mnpi_access
      layers      = v.layers
      databases   = compact(local.user_group_databases[k])
    }
  }
}
