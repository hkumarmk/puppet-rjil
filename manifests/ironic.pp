#
# Class rjil::ironic
# Gets ironic running for undercloud controllers
#

class rjil::ironic(
  $listen_address = $::ipaddress,
  $api_port       = 6385,
  $api_protocol   = 'http',
  $ssl            = false,
  $neutron_url   = 'http://localhost:9696',
) {

  class { '::ironic': }
  class { '::ironic::api': }
  class { '::ironic::conductor': }
  class { '::ironic::drivers::ipmi': }
  class { '::ironic::keystone::auth': }

  user {'ironic':
    ensure => present,
    before => [ Package['ironic-api'], Package['ironic-conductor'] ],
    tag    => 'package',
  }

  ##
  # it seems another bug in ironic packaging, /var/lib/ironic is not present.
  ##
  file {'/var/lib/ironic':
    ensure  => 'directory',
    owner   => 'ironic',
    group   => 'ironic',
    require => User['ironic']
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

  ironic_config { 'conductor/api_url':
    value => "${api_protocol}://${listen_address}:${api_port}/"
  }

  ironic_config { 'neutron/url': value => $neutron_url }

  package { 'tftpd-hpa':
    ensure => 'present'
  } ->
  file { '/etc/default/tftpd-hpa':
    source => 'puppet:///modules/rjil/tftpd-hpa.default'
  }

  rjil::jiocloud::consul::service { 'ironic':
    tags          => ['real'],
    port          => $api_port,
  }

  rjil::test::check {'tftp':
    type       => 'udp',
    check_type => 'validation',
    port       => 69
  }

  rjil::test::check {'ironic':
    port => $api_port,
    ssl  => $ssl,
  }


  rjil::jiocloud::consul::service { 'ironic-conductor':
    tags          => ['real'],
  }

  rjil::test::check {'ironic-conductor':
    type       => 'proc',
  }

  ##
  # Workaround on package issue on ironic
  ##
  ::sudo::conf { 'ironic':
    ensure  => present,
    content => "#Managed By Puppet
Defaults:ironic !requiretty
ironic ALL = (root) NOPASSWD: /usr/bin/ironic-rootwrap",
    require => User['ironic'],
  }

  # Automatically enrol the nodes which are get IP from undercloud controller
  # dhcp server.
  # NOTE: currently for some reason updating ironic from dhcp is not working,
  # which will be checking later. Until that work, this is the workaround.
  ##

  file {'/usr/lib/jiocloud/enroll_all_nodes.sh':
    ensure =>  'file',
    mode   => '0751',
    content => 'for i in `grep cip /var/lib/dhcp/dhcpd.leases  | cut -f2 -d\'"\'`; do /usr/lib/jiocloud/enroll_nodes.sh $i ; done',
  }

  cron {'enroll_all_nodes':
    ensure  => present,
    command => '/usr/lib/jiocloud/enroll_all_nodes.sh',
    user    => 'root',
    hour    => 2,
    minute  => 0,
  }

}
