# Define VLAN interfaces for each VLAN on main_bridge
resource "routeros_interface_vlan" "vlan" {
  for_each = var.vlans

  name            = each.value.vlan_name
  vlan_id         = each.value.vlan_id
  interface       = var.bridge_name
  use_service_tag = false
}

# Add all relevant physical interfaces to the bridge
resource "routeros_bridge_port" "physical_bridge_ports" {
  for_each = local.physical_interfaces # Iterate over unique physical interface names

  bridge    = var.bridge_name
  interface = each.key # each.key will be the interface name, e.g., "ether2"
  pvid      = lookup(local.interface_pvid_map, each.key, 1) # Default to PVID 1 if not an explicitly untagged port
  hw        = true
}

# Bridge VLAN configurations for each VLAN on main_bridge
resource "routeros_bridge_vlan" "bridge_vlan" {
  for_each = { for vlan_key, vlan in var.vlans : vlan_key => vlan }

  bridge   = var.bridge_name
  vlan_ids = [each.value.vlan_id]
  tagged   = each.value.tagged_interfaces
  untagged = each.value.untagged_interfaces
}

# Update IP address configuration for each VLAN
resource "routeros_ip_address" "vlan_ip" {
  for_each  = var.vlans
  address   = "${each.value.ip_address}/24"
  interface = routeros_interface_vlan.vlan[each.key].name
}

# Configure DNS settings with remote requests enabled
resource "routeros_ip_dns" "dns_settings" {
  allow_remote_requests = true
  servers               = ["1.1.1.1", "8.8.8.8"]
}

# Single default route for Internet access through Digi router
resource "routeros_ip_route" "default_route" {
  dst_address = "0.0.0.0/0"
  gateway     = "192.168.0.1"
  distance    = 1
}

# Static route for access to the 192.168.0.0/24 network through 192.168.0.2
resource "routeros_ip_route" "route_to_192_168_0" {
  dst_address = "192.168.0.0/24" # Destination network
  gateway     = "192.168.0.2"    # Gateway (MikroTik IP in that LAN)
  distance    = 1                # Route distance
}

# # Broad inter-VLAN route for 192.168.0.0/16 range
# resource "routeros_ip_route" "vlan_intercommunication" {
#   dst_address = "192.168.0.0/16"  # Allow communication across all 192.168.x.x subnets
#   gateway     = "main_bridge"
#   distance    = 1
# }

# # Assign the CIDR 192.168.0.0/24 to ether1
# resource "routeros_ip_address" "ether1_ip" {
#   address   = "192.168.0.0/24"
#   interface = "ether1"
#
#   lifecycle {
#     ignore_changes = [address]
#   }
# }