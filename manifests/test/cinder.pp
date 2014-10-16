#
# Class: rjil::test::cinder
#   Adding tests for cinder services
#

class rjil::test::cinder(
) {

  include openstack_extras::auth_file

  include rjil::test::base

  file { '/usr/lib/jiocloud/tests/cinder-api.sh':
    source => 'puppet:///modules/rjil/tests/cinder-api.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/lib/jiocloud/tests/cinder-scheduler.sh':
    source => 'puppet:///modules/rjil/tests/cinder-scheduler.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/lib/jiocloud/tests/cinder-volume.sh':
    source => 'puppet:///modules/rjil/tests/cinder-volume.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

}
