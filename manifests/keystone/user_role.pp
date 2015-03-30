##
# Define: rjil::keystone::user_role
#
# == Purpose: assign user roles to tenants
##

define rjil::keystone::user_role (
  $username,
  $tenant = $name,
  $roles  = ['_member_'],
) {

  keystone_user_role { "${username}@${tenant}":
    roles => $roles,
  }
}
