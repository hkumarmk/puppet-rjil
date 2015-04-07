###
## Class: rjil::contrail
###
class rjil::contrail::server () {

  ##
  # Added tests
  ##
  $contrail_tests = ['ifmap.sh','contrail-analytics.sh','contrail-api.sh',
                      'contrail-control.sh','contrail-discovery.sh',
                      'contrail-dns.sh','contrail-schema.sh',
                      'contrail-webui-webserver.sh','contrail-webui-jobserver.sh']
  rjil::test {$contrail_tests:}

  ensure_resource( 'rjil::service_blocker', 'cassandra', {})
  ensure_resource( 'rjil::service_blocker', 'zookeeper', {})

  Rjil::Service_blocker['cassandra'] -> Package['contrail-config-openstack']
  Rjil::Service_blocker['cassandra'] -> Package['contrail-control']
  Rjil::Service_blocker['cassandra'] -> Package['contrail-dns']
  Rjil::Service_blocker['cassandra'] -> Package['contrail-analytics']

  Rjil::Service_blocker['zookeeper'] -> Package['contrail-config-openstack']
  Rjil::Service_blocker['zookeeper'] -> Package['contrail-control']
  Rjil::Service_blocker['zookeeper'] -> Package['contrail-dns']
  Rjil::Service_blocker['zookeeper'] -> Package['contrail-analytics']


  Package['zookeeper'] -> Package['contrail-config-openstack']
  Package['zookeeper'] -> Package['contrail-control']
  Package['zookeeper'] -> Package['contrail-dns']
  Package['zookeeper'] -> Package['contrail-analytics']

  Package['dsc'] -> Package['contrail-config-openstack']
  Package['dsc'] -> Package['contrail-control']
  Package['dsc'] -> Package['contrail-dns']
  Package['dsc'] -> Package['contrail-analytics']

  include ::contrail
}
