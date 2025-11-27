locals {
  flattened_acls = flatten([
    for username, permissions in var.user_acls : [
      for perm in permissions : {
        key             = "${username}-${perm.resource_type}-${perm.resource_name}-${perm.operation}"
        principal       = "User:${username}"
        resource_name   = perm.resource_name
        resource_type   = perm.resource_type
        operation       = perm.operation
        permission_type = coalesce(perm.permission_type, "Allow")
        host            = coalesce(perm.host, "*")
      }
    ]
  ])
}