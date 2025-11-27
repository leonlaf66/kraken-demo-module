resource "kafka_topic" "this" {
  for_each = { for t in var.topics : t.name => t }

  name               = each.value.name
  replication_factor = each.value.replication_factor
  partitions         = each.value.partitions
  config             = each.value.config
}

resource "kafka_acl" "this" {
  for_each = { for acl in local.flattened_acls : acl.key => acl }

  resource_name       = each.value.resource_name
  resource_type       = each.value.resource_type
  acl_principal       = each.value.principal
  acl_host            = each.value.host
  acl_operation       = each.value.operation
  acl_permission_type = each.value.permission_type
}