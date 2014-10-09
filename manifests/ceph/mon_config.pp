#
# Class: rjil::ceph::mon_config
#  Setup mon configuration for ceph storage nodes and clients except mon
#  nodes.
#  NOTE:: MON NODES WILL USE rjil::ceph::mon::mon_config
#

class rjil::ceph::mon_config (
  $mon_service_name = 'stmon.service.consul',
) {

  ##
  # mon_config is array of IP addresses which is resolved for
  # stmon.service.consul
  ##
  $mon_config = split(dns_resolve($mon_service_name),',')

  ##
  # Configure mon details
  ##
  ::ceph::conf::mon_config{ $mon_config: }

}
