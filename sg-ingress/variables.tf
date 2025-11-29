variable "ingress_rules" {
  type = map(object({
    description                  = string
    security_group_id            = string
    from_port                    = number
    to_port                      = number
    ip_protocol                  = string
    cidr_ipv4                    = optional(string, null)
    referenced_security_group_id = optional(string, null)
  }))

  validation {
    condition = alltrue([
      for k, v in var.ingress_rules :
      (v.cidr_ipv4 != null && v.referenced_security_group_id == null) ||
      (v.cidr_ipv4 == null && v.referenced_security_group_id != null)
    ])
    error_message = "Each rule must specify either cidr_ipv4 OR referenced_security_group_id, not both or neither."
  }
}