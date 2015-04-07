#
# Class: rjil::cassandra
#  This class to manage contrail cassandra dependency. Added parameters here to
#  set appropriate defaults, so that hiera config is not required unless any
#  extra configruation.
#
# == Hiera elements
#
# rjil::cassandra::seeds:
#   An array of all cassandra nodes
#
# rjil::cassandra::cluster_name:
#   Cassandra cluster name
# Default: 'contrail'
#
# rjil::cassandra::thread_stack_size:
#   JVM threadstack size for cassandra in KB.
#   Default value in cassandra module cause cassandra startup to fail, due to
#   low jvm thread stack size,
#   Default: 300
#
# rjil::cassandra::version:
#   Cassandra module doesnt support cassandra version 2.x. Also current contrail
#   implementation uses cassandra 1.2.x, so to provide version to avoid
#   installing latest package version which is 2.x
#
# rjil::cassandra::package_name:
#    Cassandra package name, the package name contains the major versions, so
#    have to set the package name.

class rjil::cassandra (
  $seeds        = [$::ipaddress],
  $cluster_name =  'contrail',
  $thread_stack_size = 300,
  $version      = '1.2.18-1',
  $package_name  = 'dsc12',
) {

  rjil::test { 'check_cassandra.sh': }
  # make sure that hostname is resolvable or cassandra fails
  host { 'localhost':
    ip => '127.0.0.1',
    host_aliases => ['localhost.localdomain', $::hostname],
  }

  if $thread_stack_size < 229 {
    fail("JVM Thread stack size (thread_stack_size) must be > 230")
  }
  class {'::cassandra':
    seeds             => $seeds,
    cluster_name      => $cluster_name,
    thread_stack_size => $thread_stack_size,
    version           => $version,
    package_name      => $package_name,
    require           => Host['localhost'],
  }

  ##
  # I dont know if the port check is enough here - refer
  # https://github.com/JioCloud/puppet-rjil/issues/521 for more details
  ##
  rjil::jiocloud::consul::service { "cassandra":
    tags          => ['real','contrail'],
    check_command => '/usr/lib/jiocloud/tests/check_cassandra.sh',
  }

}
