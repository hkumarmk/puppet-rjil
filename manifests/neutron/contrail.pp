#
# Class: rjil::neutron::contrail
#

# [* public_subnets *]
#   is a hash of subnetlogicalname => cidr
#   e.g { pub_subnet1 => '100.1.0.0/16'}

# NOTE: Public network will be created on services tenant. In order to specify
# specific tenant name on which public network created, keystone.conf required
# on neutron server which is not the case as of now.

class rjil::neutron::contrail(
  $keystone_admin_password,
  $public_network_name    = 'public',
  $public_subnet_name     = 'pub_subnet1',
  $public_cidr            = undef,
  $public_rt_number       = 10000,
  $router_asn             = 64512,
  $public_subnet_ip_start = undef,
  $public_subnet_ip_end   = undef,
  $contrail_api_server    = 'real.neutron.service.consul',
) {

  include ::rjil::neutron

  ##
  # Database connection is not required for contrail
  ##

  Neutron_config<| title == 'database/connection' |> {
    ensure => absent
  }

  ##
  # Subscribe neutron-server to contrailplugin.ini
  ##

  File['/etc/neutron/plugins/opencontrail/ContrailPlugin.ini'] ~>
    Service['neutron-server']

  include rjil::contrail::server

  ##
  # Add route target in contrail config database.
  ##
  contrail_rt {"default-domain:services:${public_network_name}":
    ensure             => present,
    rt_number          => $public_rt_number,
    router_asn         => $router_asn,
    api_server_address => $contrail_api_server,
    admin_password     => $keystone_admin_password,
    require            => Neutron_network[$public_network_name],
  }

  consul_kv{'neutron/floatingip_pool/status':
    value   => 'ready',
    require => Contrail_rt["default-domain:services:${public_network_name}"],
  }

  if $public_cidr {
    ##
    # Add floating IPs
    ##

    neutron_network {$public_network_name:
      ensure          => present,
      router_external => true,
    }

    if $subnet_ip_start {
      if !$subnet_ip_end {
        fail('subnet_ip_end is required if subset of IPs to be added to subnet')
      }

      neutron_subnet {$public_subnet_name:
        ensure           => present,
        cidr             => $public_cidr,
        network_name     => $public_network_name,
        allocation_pools => ["start=$public_subnet_ip_start,end=$public_subnet_ip_end"],
        before           => Contrail_rt["default-domain:services:${public_network_name}"],
      }
    } else {
      neutron_subnet {$public_subnet_name:
        ensure       => present,
        cidr         => $public_cidr,
        network_name => $public_network_name,
        before       => Contrail_rt["default-domain:services:${public_network_name}"],
      }
    }
  }
}
