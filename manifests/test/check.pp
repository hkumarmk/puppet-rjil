#
# Class: rjil::test::cinder
#   Adding tests for cinder services
#
# [*test_consumer*]

define rjil::test::check(
  $port     = 0,
  $address  = '127.0.0.1',
  $ssl      = false,
  $type     = 'http',
  $consumer = 'consul_service',
) {

  include rjil::test::base

  if $consumer == 'consul_service' {
    $file_path = "/usr/lib/jiocloud/tests/service_checks/${name}.sh"
  } elsif $consumer == 'validation' {
    $file_path = "/usr/lib/jiocloud/tests/${name}.sh"
  }

  file { $file_path:
    content => template("rjil/tests/${type}_check.sh.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

}
