#
# Class rjil::ironic
# Gets ironic running for undercloud controllers
#

class rjil::ironic(
  $deploy_ironic_api_url = "http://${::ipaddress}:6385/",
) {
  class { '::rabbitmq': }

  class { '::nova::compute': }
  class { '::nova::compute::ironic' :}

  class { '::ironic': }
  class { '::ironic::api': }
  class { '::ironic::conductor': }
  class { '::ironic::drivers::ipmi': }
  class { '::ironic::keystone::auth': }

  file { '/etc/init/nova-compute.conf':
    source => 'puppet:///modules/rjil/nova-compute.conf',
    notify => Service['nova-compute']
  }

  file { '/etc/default/neutron-server':
    source => 'puppet:///modules/rjil/neutron-server.defaults',
  }

  user {'ironic':
    ensure => present,
    before => [ Package['ironic-api'], Package['ironic-conductor'] ],
    tag    => 'package',
  }

  file { '/tftpboot':
    ensure => 'directory',
    owner  => 'ironic',
    group  => 'ironic',
  } ->
  file { '/tftpboot/pxelinux.cfg':
    ensure => 'directory',
    owner  => 'ironic',
    group  => 'ironic',
  } ->
  file { '/tftpboot/pxelinux.0':
    owner   => 'ironic',
    group   => 'ironic',
    source  => '/usr/lib/syslinux/pxelinux.0',
    require => Package['syslinux']
  } ->
  file { '/tftpboot/map-file':
    owner  => 'ironic',
    group  => 'ironic',
    source => 'puppet:///modules/rjil/tftpd.map-file',
  }

  package { 'ipmitool':
    ensure => 'present'
  }

  package { 'syslinux':
    ensure => 'present'
  }

  ironic_config { 'conductor/ironic_api_url': value => $deploy_ironic_api_url }

  package { 'tftpd-hpa':
    ensure => 'present'
  } ->
  file { '/etc/default/tftpd-hpa':
    source => 'puppet:///modules/rjil/tftpd-hpa.default'
  }

  rjil::jiocloud::consul::service { 'ironic':
    tags          => ['real'],
    port          => 6385,
    check_command => "/usr/lib/nagios/plugins/check_http -I 0.0.0.0 -p 6385"
  }
}
