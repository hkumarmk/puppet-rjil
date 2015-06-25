#
# Class: rjil::nova::compute
#
# == Description: Setup nova compute
#
# == Parameters
#
# [*rbd_enabled*]
#   whether rbd is enabled or not, if rbd is enabled, ceph specific
#   configurations would be added.
#   with the current setup, rbd is not going to work with ironic, so this
#   parameter have no effect in case of ironic compute_driver.
#
# [*consul_check_interval*]
#   Consul service health check interval
#
# [*compute_driver*]
#   Which compute driver to be used, example: libvirt, ironic. Default: libvirt.
#

class rjil::nova::compute (
  $rbd_enabled           = true,
  $consul_check_interval = '120s',
  $compute_driver        = 'libvirt',
) {

  #
  # Add tests for nova compute
  ##

  include rjil::test::compute

  ensure_resource('package','python-six', { ensure => 'latest' })

  include rjil::nova::zmq_config
  include ::nova::client
  include ::nova
  include ::nova::compute
  include ::nova::network::neutron

  ##
  # call compute driver specific classes
  ##
  include "::nova::compute::${compute_driver}"

  ##
  # ironic doesnt need vif specific configurations.
  ##
  if $compute_driver == 'libvirt' {
    include ::nova::compute::neutron

    Package['libvirt'] -> Exec['rm_virbr0']

    ##
    # if rbd is enabled, configure ceph.
    # rbd will not support ironic with current setup, so only to be enabled in
    # case of libvirt.
    ##
    if $rbd_enabled {
      include ::rjil::nova::compute::rbd
    }
  }


  rjil::jiocloud::logrotate { 'nova-compute':
    logdir => '/var/log/nova/'
  }

  include rjil::nova::logrotate::manage

  ##
  # Remove libvirt default nated network
  ##
  exec { 'rm_virbr0':
    command => 'virsh net-destroy default && virsh net-undefine default',
    path    => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin',
    onlyif  => 'virsh -q net-list | grep -q default' ,
  }

  rjil::jiocloud::consul::service {'nova-compute':
    port          => 0,
    check_command => "sudo nova-manage service list | grep 'nova-compute.*${::hostname}.*enabled.*:-)'",
    interval      => $consul_check_interval,
  }

  ensure_resource(package, 'ethtool')

  Package <| name == 'ethtool' |> ->
  file { '/etc/init/disable-gro.conf':
    source => 'puppet:///modules/rjil/disable-gro.conf',
    owner  => 'root',
    group  => 'root',
    mode   => '0644'
  } ~>
  exec { 'disable-gro':
    command     => 'true ; cd /sys/class/net ; for x in *; do ethtool -K $x gro off || true; done',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin',
    refreshonly => true
  }

  ##
  # Specifically deny read access to /run/shm/lttng for vms. This will remove
  # the apparmor warnings on compute nodes.
  ##
  file_line {'apparmor_deny_read_lttng':
    path    => '/etc/apparmor.d/abstractions/libvirt-qemu',
    line    => '  deny /run/shm/lttng* r,',
    require => Package['libvirt'],
    notify  => Service['apparmor'],
  }
}
