#
# class rjil::openstack_config::neutron
#   Most of the openstack object management providers need keystone auth config
#   on specific configuration file - say for neutron_network, neutron_subnet
#   providers look for keystone auth entries in /etc/neutron/neutron.conf. So
#   adding class so that it can be included whereever required these config
#   entries (this is only required if neutron is NOT configured on the node from
#   where these providers are getting called).
#
class rjil::openstack_config::neutron (
  $auth_host      = 'identity.jiocloud.com',
  $auth_port      = 5000,
  $auth_protocol  = 'https',
  $service_tenant = 'services',
  $admin_user     = 'neutron',
  $admin_password = 'neutron',
) {

  file {'/etc/neutron':
    ensure => directory,
  }

  file {'/etc/neutron/neutron.conf':
    ensure  => file,
    require => File['/etc/neutron'],
  }

  File['/etc/neutron/neutron.conf'] -> Neutron_config<||>
  Neutron_config<||> -> Neutron_network<||>
  Neutron_config<||> -> Neutron_subnet<||>

  neutron_config {
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/auth_port':         value => $auth_port;
    'keystone_authtoken/auth_protocol':     value => $auth_protocol;
    'keystone_authtoken/admin_tenant_name': value => $service_tenant;
    'keystone_authtoken/admin_user':        value => $admin_user;
    'keystone_authtoken/admin_password':    value => $admin_password;
  }
}
