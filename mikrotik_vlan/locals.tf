locals {
  # Aggregation of untagged interfaces for bridge ports
  untagged_interfaces = flatten([
    for vlan_key, vlan in var.vlans : [
      for iface in vlan.untagged_interfaces : {
        interface = iface
        vlan_id   = vlan.vlan_id
        pvid      = vlan.vlan_id # Set PVID for untagged VLAN traffic
        bridge    = var.bridge_name
      }
    ]
  ])

  # Aggregation of tagged interfaces for bridge ports
  tagged_interfaces = flatten([
    for vlan_key, vlan in var.vlans : [
      for iface in vlan.tagged_interfaces : {
        interface = iface
        vlan_id   = vlan.vlan_id
        pvid      = null # Tagged traffic does not use PVID
        bridge    = var.bridge_name
      }
    ]
  ])

  # Combine tagged and untagged interfaces for bridge port setup
  all_interfaces = concat(local.untagged_interfaces, local.tagged_interfaces)

  # Gather unique physical interfaces for bridge ports
  physical_interfaces = toset([for iface in local.all_interfaces : iface.interface])

  # Define subnets for each VLAN
  vlan_subnets = {
    for vlan_key, vlan in var.vlans :
    vlan_key => vlan.vlan_subnet # Use the vlan_subnet directly as it is already in CIDR format
  }

  # Gateway IPs for each VLAN subnet, using the first host as gateway
  vlan_gateways = {
    for vlan_key, subnet in local.vlan_subnets :
    vlan_key => cidrhost(subnet, 1)
  }

  interface_pvid_map = {
    for item in local.untagged_interfaces : item.interface => item.vlan_id
  }
}