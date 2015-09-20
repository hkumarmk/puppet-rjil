#
# Class rjil::keystone::objects
#  To create keystone users, tenants and endpoints for all services.
#
class rjil::keystone::objects (
  $users                   = {},
  $tenants                 = undef,
  $roles                   = undef,
) {

  ensure_resource( 'rjil::service_blocker', 'keystone-admin', {})
  ensure_resource( 'rjil::service_blocker', 'keystone', {})

  Rjil::Service_blocker['keystone-admin'] ->
  Rjil::Service_blocker['keystone'] ->
  Class['openstack_extras::keystone_endpoints']

  # provision keystone objects for all services
  include ::openstack_extras::keystone_endpoints

  # create users, tenants, roles, default networks
  create_resources('rjil::keystone::user',$users)

  ##
  # Tenants can be created without creating users, $tenants can be an array of
  # all tenant names to be created, and a hash of tenants with appropriate
  # params for rjil::keystone::tenant
  ##
  if is_array($tenants) {
    rjil::keystone::tenant { $tenants: }
  } elsif is_hash($tenants) {
    create_resources('rjil::keystone::tenants',$tenants)
  }

  if is_array($roles) {
    keystone_role { $roles:
      ensure => present,
    }
  } elsif is_hash($roles) {
    create_resources('keystone_role',$roles,{ensure =>present})
  }

}
