resource "unifi_network" "servers" {
  name    = "Servers"
  site    = unifi_site.default.name
  vlan_id = 10

  dhcp_dns            = []
  dhcp_enabled        = false
  dhcp_lease          = 0
  dhcp_relay_enabled  = false
  dhcpd_boot_enabled  = false
  igmp_snooping       = false
  ipv6_interface_type = "none"
  ipv6_ra_enable      = false
  network_group       = "LAN"
  purpose             = "vlan-only"
  wan_dns             = []
  wan_egress_qos      = 0
}

resource "unifi_network" "iot" {
  name    = "IoT"
  site    = unifi_site.default.name
  vlan_id = 40

  dhcp_dns            = []
  dhcp_enabled        = false
  dhcp_lease          = 0
  dhcp_relay_enabled  = false
  dhcpd_boot_enabled  = false
  igmp_snooping       = false
  ipv6_interface_type = "none"
  ipv6_ra_enable      = false
  network_group       = "LAN"
  purpose             = "vlan-only"
  wan_dns             = []
  wan_egress_qos      = 0
}
