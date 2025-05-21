variable "bridge_name" {
  description = "The name of the bridge to manage"
  type        = string
  default     = "vlans_bridge" # Matches the bridge used for VLAN traffic
}

variable "username" {
  description = "Username for RouterOS"
  type        = string
}

variable "password" {
  description = "Password for RouterOS"
  type        = string
  sensitive   = true
}

variable "vlans" {
  description = "Map of VLANs to configure"
  type = map(object({
    vlan_id             = number
    vlan_name           = string
    vlan_subnet         = string # CIDR format for subnet address
    untagged_interfaces = list(string)
    tagged_interfaces   = list(string)
    ip_address          = string # IP address for the VLAN interface
    dhcp_enabled        = bool
    dhcp_pool_range     = string
    dhcp_dns_servers    = list(string)
    routing_table       = optional(string) # Add this line if routing tables are required
  }))

  validation {
    condition     = alltrue([for vlan in values(var.vlans) : can(regex("^[a-zA-Z0-9_-]+$", vlan.vlan_name))])
    error_message = "All VLAN names must be alphanumeric and can include underscores or hyphens."
  }

  validation {
    condition     = alltrue([for vlan in values(var.vlans) : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", vlan.ip_address))])
    error_message = "All VLAN ip_address fields must be a valid IPv4 address format (e.g., 192.168.1.1)."
  }

  validation {
    condition     = alltrue([for vlan in values(var.vlans) : can(regex("^(10\\.|172\\.(1[6-9]|2[0-9]|3[01])\\.|192\\.168\\.)", vlan.vlan_subnet))])
    error_message = "All VLAN subnets must start with an RFC 1918 private address prefix (10.x.x.x, 172.16.x.x-172.31.x.x, 192.168.x.x)."
  }

  validation {
    condition     = alltrue([for vlan in values(var.vlans) : !vlan.dhcp_enabled || can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}-([0-9]{1,3}\\.){3}[0-9]{1,3}$", vlan.dhcp_pool_range))])
    error_message = "For DHCP-enabled VLANs, the dhcp_pool_range must be in the format 'IP_START-IP_END'."
  }

  validation {
    condition     = length(distinct([for vlan in values(var.vlans) : vlan.vlan_id])) == length([for vlan in values(var.vlans) : vlan.vlan_id])
    error_message = "VLAN IDs must be unique across all VLAN definitions."
  }

  validation {
    condition     = length(distinct([for vlan in values(var.vlans) : vlan.vlan_subnet])) == length([for vlan in values(var.vlans) : vlan.vlan_subnet])
    error_message = "VLAN subnets must be unique across all VLAN definitions."
  }
}