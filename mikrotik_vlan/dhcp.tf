# DHCP Pool for each VLAN
resource "routeros_ip_pool" "dhcp_pool" {
  for_each = { for vlan_key, vlan in var.vlans : vlan_key => vlan if vlan.dhcp_enabled }

  name   = "dhcp_pool_${each.key}"
  ranges = [each.value.dhcp_pool_range]
}

# DHCP Server for each VLAN
resource "routeros_dhcp_server" "dhcp_server" {
  for_each = { for vlan_key, vlan in var.vlans : vlan_key => vlan if vlan.dhcp_enabled }

  name             = "dhcp_${each.key}"
  interface        = routeros_interface_vlan.vlan[each.key].name
  address_pool     = routeros_ip_pool.dhcp_pool[each.key].name
  lease_time       = var.default_lease_time
  always_broadcast = true
}

# DHCP Network Configuration for each VLAN
resource "routeros_dhcp_server_network" "dhcp_network" {
  for_each = { for vlan_key, vlan in var.vlans : vlan_key => vlan if vlan.dhcp_enabled }

  address    = each.value.vlan_subnet
  gateway    = cidrhost(each.value.vlan_subnet, 1)
  dns_server = each.value.dhcp_dns_servers
}