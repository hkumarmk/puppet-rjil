#
# Class: rjil::neutron::ovs
#

class rjil::neutron::ovs(
  $ctlplane_address,
  $ctlplane_netmask,
  $ctlplane_network,
  $ctlplane_broadcast,
  $ctlplane_gateway,
  $ctlplane_cidr,
  $ctlplane_dhcp_start,
  $ctlplane_dhcp_end,
  $ctlplane_network_name       = 'ctlplane',
  $ctlplane_physical_interface = 'eth0',
  $ctlplane_nameservers        = '8.8.8.8',
  $ctlplane_domain             = 'undercloud.local',
) {

  include ::rjil::neutron

  contain ::neutron::plugins::ovs

  contain ::neutron::agents::ml2::ovs

  neutron_plugin_ovs {
    'OVS/bridge_mappings':   value => "${ctlplane_network_name}:br-${ctlplane_network_name}";
  }

  class { '::neutron::agents::dhcp':
    require => File['/etc/init/neutron-plugin-openvswitch-agent.conf']
  }

  class { '::neutron::agents::l3': } # Is this needed at all? I don't think so. - Soren

  vs_bridge { "br-${ctlplane_network_name}":
    ensure => present,
  } ->
  vs_port { $ctlplane_physical_interface:
    ensure => present,
    bridge => "br-${ctlplane_network_name}",
  } ->
  file { '/etc/network/interfaces.new':
    content => template('rjil/undercloud_etc_network_interfaces.tmpl'),
    notify => Exec['network-down']
  } ~>
  exec { 'network-down':
    command     => '/sbin/ifdown -a',
    refreshonly => true,
  } ->
  file { '/etc/network/interfaces':
    source => '/etc/network/interfaces.new'
  } ~>
  exec { 'network-up':
    command     => '/sbin/ifup -a',
    refreshonly => true,
  }

  neutron_network { "${ctlplane_network_name}":
    tenant_name               => 'openstack',
    provider_network_type     => 'flat',
    provider_physical_network => "${ctlplane_network_name}",
  }

  neutron_subnet { "${ctlplane_network_name}":
    cidr             => $ctlplane_cidr,
    ip_version       => '4',
    allocation_pools => ["start=${ctlplane_dhcp_start},end=${ctlplane_dhcp_end}"],
    gateway_ip       => $ctlplane_gateway,
    enable_dhcp      => true,
    host_routes      => ["destination=169.254.169.254/32,nexthop=${::ipaddress}"],
    network_name     => "${ctlplane_network_name}",
    tenant_name      => 'openstack',
  }

  file { '/etc/init/neutron-plugin-openvswitch-agent.conf':
    source => 'puppet:///modules/rjil/neutron-plugin-openvswitch-agent.conf',
  }

}
