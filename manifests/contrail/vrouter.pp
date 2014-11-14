###
# Class: rjil::contrail::vrouter
#
# $discovery_ip: ideally this should be resolved from
# lb.discovery.service.consul, but for this it need some more work to see the
# impact of moving haproxy to lb. This will be worked on with multi-node
# contrail setup.

###
class rjil::contrail::vrouter (
  $discovery_ip = join(service_discover_dns('real.neutron.service.consul','ip')),
  $api_ip       = undef,
) {

  ##
  # Vgw need floating IP pool to be created before it can successfully created
  # it, I dont know if this is handled in contrail code. Trying service blocker
  # here to see if that work.
  ##

  ensure_resource( 'rjil::service_blocker', 'neutron', {})
  Rjil::Service_blocker['neutron'] -> Contrail_vgw<||>

  include nova::compute::libvirt

  Package['libvirt'] ->
  File_line['cgroup_device_acl']

  file_line {'cgroup_device_acl':
    path => '/etc/libvirt/qemu.conf',
    line => 'cgroup_device_acl = [ "/dev/null", "/dev/full", "/dev/zero", "/dev/random", "/dev/urandom", "/dev/ptmx", "/dev/kvm", "/dev/kqemu", "/dev/rtc", "/dev/hpet","/dev/net/tun", ]',
    notify => Service['libvirt'],
  }

  class {'::contrail::vrouter':
    discovery_ip => $discovery_ip,
    api_ip       => $api_ip,
  }
}
