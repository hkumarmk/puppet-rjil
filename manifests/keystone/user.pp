##
# Define: rjil::keystone::user
#
# == Purpose: create the users, tenants, roles
#
##
define rjil::keystone::user (
  $password,
  $username       = $name,
  $email          = "${name}@jiocloud.local",
  $tenants        = [$name],
  $roles          = ['_member_']
  $create_network = true,
) {

  keystone_tenant { $tenants:
    ensure      => present,
    enabled     => true,
  }

  keystone_user { $username:
    ensure   => present,
    enabled  => true,
    email    => $email,
    password => $password,
  }

  ##
  # Create user roles for all tenants he need to have
  ##
  rjil::keystone::user_role { $tenants:
    username => $username,
    roles    => $roles,
  }

  ##
  # It may be useful to have a default network with subnet created. Another
  # reason to create the networks because we may hit contrail bug 1353325 if we
  # anted to use rjil::neutron::contrail::fip_pool
  ##
  if $create_network {
    rjil::keystone::default_network {$tenants: }
  }
}
