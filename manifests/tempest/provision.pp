#
# This is WIP, just adding required route to get floating IP accessible now.
#
class rjil::tempest::provision (
  $auth_host              = 'lb.keystone.service.consul',
  $auth_port              = 35357,
  $auth_protocol          = 'http',
  $service_tenant         = 'services',
  $neutron_admin_user     = 'neutron',
  $neutron_admin_password = 'neutron',
) {

##
# Create required resources in order to run tempest
##

  ##
  # Neutron_network and neutron_subnet need neutron.conf with keystone
  # configuration added. So adding appropriate entries.
  ##

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
    'keystone_authtoken/admin_user':        value => $neutron_admin_user;
    'keystone_authtoken/admin_password':    value => $neutron_admin_password;
  }

  include ::tempest::provision
  ensure_resource('rjil::service_blocker', 'lb.glance', {})
  ensure_resource('rjil::service_blocker', 'lb.neutron', {})
  ensure_resource('rjil::service_blocker', 'lb.keystone', {})

  Rjil::Service_blocker['lb.glance'] -> Glance_image<||>
  Rjil::Service_blocker['lb.neutron'] -> Neutron_network<||>
  Rjil::Service_blocker['lb.neutron'] -> Neutron_subnet<||>
  Rjil::Service_blocker['lb.keystone'] -> Keystone_user<||>
  Rjil::Service_blocker['lb.keystone'] -> Keystone_role<||>
  Rjil::Service_blocker['lb.keystone'] -> Keystone_user_role<||>
  Rjil::Service_blocker['lb.keystone'] -> Keystone_tenant<||>

}

