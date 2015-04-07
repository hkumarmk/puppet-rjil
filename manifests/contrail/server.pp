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

  include ::contrail
}
