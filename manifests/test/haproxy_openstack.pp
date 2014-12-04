class rjil::test::haproxy_openstack(
  $vip         = '127.0.0.1',
  $ports  = [],
) {

  include rjil::test::base

  file { "/usr/lib/jiocloud/tests/haproxy_openstack.sh":
    content => template('rjil/tests/haproxy_openstack.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '755',
  }

}
