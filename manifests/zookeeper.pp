#
# Class: rjil::zookeeper
#  This class to manage contrail zookeeper dependency
#
# == Parameters
#
# [*zk_id*]
#    Zookeeper server ID - this is unique integer ID between 1-255, this must be
#    unique for gieven server in zookeeper cluster.
#  Default: automatically generated from its first NIC's IP address
#

class rjil::zookeeper (
  $zk_id = regsubst($::ipaddress,'^(\d+)\.(\d+)\.(\d+)\.(\d+)$','\4')
) {

  rjil::test { 'check_zookeeper.sh': }

  class { '::zookeeper':
    id => $zk_id,
  }

  ##
  # I dont know if the port check is enough here - refer
  # https://github.com/JioCloud/puppet-rjil/issues/521 for more details
  ##
  rjil::jiocloud::consul::service { 'zookeeper':
    tags          => ['real','contrail'],
    check_command => '/usr/lib/jiocloud/tests/check_zookeeper.sh',
  }

}
