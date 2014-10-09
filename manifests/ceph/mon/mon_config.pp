#
# Define: rjil::ceph::mon::mon_config
#    Setup mon configuration for mon nodes.
#

define rjil::ceph::mon::mon_config (
  $mon_service_name = 'stmon.service.consul',
  $public_if        = eth0,
) {

  ##
  # mon_config is array of IP addresses which is resolved for
  # stmon.service.consul
  ##
  $mon_config = split(dns_resolve($mon_service_name),',')

  ##
  # Ceph mon configuration for the same node must have following properties
  #   1. mon name must match hostname, otherwise ceph upstart script will not
  #   configure it.
  #   2. mon_addr must be a valid IP address and port. Name even though it
  #   resolveable, will not work.
  # Because of above reason, mon_config is done in two step
  # 1. configure the node's own configuration with mon_name -> hostname and
  # mon_addr -> puublic interface IP address.
  # 2. Configure other mon's configuration with mon_name and mon_addr as IP
  # addresses
  ##

  $pub_ip = inline_template("<%= scope.lookupvar('ipaddress_' + @public_if) %>")

  ##
  # Step #1 as mentioned above
  ##

  ::ceph::conf::mon_config { $::hostname:
    mon_addr => $pub_ip
  }

  ##
  # step #2
  ##

  $other_mons = delete($mon_config,$pub_ip)

  if ! empty($other_mons) {
    ::ceph::conf::mon_config{ $other_mons: }
  }

}
