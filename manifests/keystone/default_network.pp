##
# Define: rjil::keystone::default_network
#
# == Purpose: Create one default network named default_network to tenant
#
# Another reason is to workaround to use rjil::neutron::contrail::fip_pool.
# Because of the contrail bug 1353325, keystone project will not be synced until
# there is a neutron object like network.
##

define rjil::keystone::default_network (
  $network_name = 'default_network',
  $subnet_name  = 'default_subnet',
  $cidr         = '192.168.0.0/24',
  $tenant       = $name,
) {

  neutron_network {$network_name:
    ensure      => present,
    tenant_name => $tenant,
  }

  neutron_subnet {$subnet_name:
    ensure       => present,
    cidr         => $cidr,
    network_name => $network_name,
    tenant_name  => $tenant,
  }
}
