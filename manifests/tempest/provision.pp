#
# This is WIP, just adding required route to get floating IP accessible now.
#
class rjil::tempest::provision (
  $auth_host              = 'identity.jiocloud.com',
  $auth_port              = 5000,
  $auth_protocol          = 'https',
  $service_tenant         = 'services',
  $neutron_admin_user     = 'neutron',
  $neutron_admin_password = 'neutron',
  $configure_neutron      = true,
) {

##
# Create required resources in order to run tempest
##

  if $configure_neutron {
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
  }

  include ::tempest::provision

}

