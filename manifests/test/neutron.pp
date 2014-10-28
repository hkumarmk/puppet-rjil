#
# Class: rjil::test::neutron
#   Adding tests for neutron services
#

class rjil::test::neutron(
) {

  include openstack_extras::auth_file

  include rjil::test::base

  file { '/usr/lib/jiocloud/tests/neutron.sh':
    source => 'puppet:///modules/rjil/tests/neutron.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
