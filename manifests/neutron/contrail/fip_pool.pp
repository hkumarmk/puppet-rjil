##
# Define rjil::neutron::contrail::fip_pool
# == This one is sole responsible for creating all floating IP pool. It support two
# types of fip pools,
# 1. floating IP pool available to all tenants,
#   This one is handled using neutron apis, and thus fip pool created using this
#   method is available to all tenants
# 2. fip pool restricted to specific tenants.
#     This is only doable using contrail apis. Note: here you have to use
#     contrail apis for everything including
#     create/delete/associate/disassociate fips.
# Parameters
# [*public*]
#   This will make the call whether the fip pool to be
##
define rjil::neutron::contrail::fip_pool (
  $network_name,
  $subnet_name,
  $cidr,
  $keystone_admin_password,
  $contrail_api_server = 'real.neutron.service.consul',
  $rt_number           = 10000,
  $router_asn          = 64512,
  $subnet_ip_start     = undef,
  $subnet_ip_end       = undef,
  $public              = true,
  $tenant_name         = 'services',
  $tenants             = [],
) {

  if $public {
    neutron_network {$network_name:
      ensure          => present,
      router_external => true,
    }
  } else {
    neutron_network {$network_name:
      ensure          => present,
    }

    contrail_fip_pool {$name:
      ensure         => present,
      network_fqname => "default-domain:${tenant_name}:${network_name}",
      tenants        => $tenants,
      require        => Neutron_network[$network_name],
    }
  }

  if $subnet_ip_start {
    if !$subnet_ip_end {
      fail('subnet_ip_end is required if subset of IPs to be added to subnet')
    }

    neutron_subnet {$subnet_name:
      ensure           => present,
      cidr             => $cidr,
      network_name     => $network_name,
      allocation_pools => ["start=${subnet_ip_start},end=${subnet_ip_end}"],
      before           => Contrail_rt["default-domain:${tenant_name}:${network_name}"],
    }
  } else {
    neutron_subnet {$subnet_name:
      ensure       => present,
      cidr         => $cidr,
      network_name => $network_name,
      before       => Contrail_rt["default-domain:${tenant_name}:${network_name}"],
    }
  }

  contrail_rt {"default-domain:${tenant_name}:${network_name}":
    ensure             => present,
    rt_number          => $rt_number,
    router_asn         => $router_asn,
    api_server_address => $contrail_api_server,
    admin_password     => $keystone_admin_password,
    require            => Neutron_network[$network_name],
  }


  ##
  # It may need to create different kv for different fip, but just making the logic simple for now.
  ##
  ensure_resource(consul_kv,'neutron/floatingip_pool/status',{ value   => 'ready' })

  Contrail_rt["default-domain:${tenant_name}:${network_name}"] -> Consul_kv['neutron/floatingip_pool/status']

}
