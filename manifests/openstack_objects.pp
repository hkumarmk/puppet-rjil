#
# This class is responsible for creating all objects in the openstack
# database.
#
# == Parameter
# [*identity_address*] Address used to resolve identity service.
#
class rjil::openstack_objects(
  $identity_address,
  $override_ips      = false,
  $users             = {},
  $tenants           = undef,
) {

  if $override_ips {
    $identity_ips = $override_ips
  } else {
    $identity_ips = dns_resolve($identity_address)
  }

  if $identity_ips == '' {
    $fail = true
  } else {
    $fail = false
  }
  # add a runtime fail and ensure that it blocks all object creation.
  # otherwise, it's possible that we might have to wait for network
  # timeouts if the dns address does not correctly resolve.
  runtime_fail {'keystone_endpoint_not_resolvable':
    fail => $fail
  }

  Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_user<||>
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_role<||>
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_tenant<||>
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_service<||>
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_endpoint<||>
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Rjil::Service_blocker['lb.glance']
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Rjil::Service_blocker['lb.neutron']

  ensure_resource('rjil::service_blocker', 'lb.glance', {})
  ensure_resource('rjil::service_blocker', 'lb.neutron', {})

  Rjil::Service_blocker['lb.glance'] -> Glance_image<||>
  Rjil::Service_blocker['lb.neutron'] -> Neutron_network<||>

  # provision keystone objects for all services
  include openstack_extras::keystone_endpoints
  # provision tempest resources like images, network, users etc.
  include tempest::provision

  # create users, tenants, roles, default networks
  create_resources('rjil::keystone::users',$users)

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

}
