#
# Class: rjil::test::keystone
#   Adding tests for nova services
#

class rjil::test::keystone {

  include openstack_extras::auth_file

  file { "/usr/lib/jiocloud/tests/keystone.sh":
    content => template('rjil/tests/keystone.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }    

}
