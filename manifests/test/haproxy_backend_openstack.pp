class rjil::test::haproxy_backend_openstack(
  $backend_services  = {},
  $status_check      = true,
) {

  include rjil::test::base

  package {'socat':
    ensure => installed,
  }

  file { "/usr/lib/jiocloud/tests/haproxy_backend_openstack.sh":
    content => template('rjil/tests/haproxy_backend_openstack.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '755',
  }

}
