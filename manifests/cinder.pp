#
# Class: rjil::cinder
#   Setup openstack cinder.
#
# == Parameters
#
# [*ceph_mon_key,*]
#   Ceph mon key. This is required to generate the keys for additional users.
#
# [*rpc_backend*]
#   rpc backend - we use zmq for zeromq.
#
# [*rpc_zmq_bind_address*]
#   which address to bind zmq receiver. Default: '*' - all addresses
#
# [*rpc_zmq_contexts*]
#   Number of zmq contexts. Default: 1
#
# [*rpc_zmq_matchmaker*]
#   Matchmaker driver. Currently only MatchMakerRing supported.
#
# [*rpc_zmq_port*]
#   Zmq receiver port. Default:9501
#
# [*ceph_keyring_file_owner*]
#   The owner of ceph keyring, this file must be readable by cinder user.
#   Default: cinder
#
# [*ceph_keyring_path*]
#   Path to keyring.
#
# [*ceph_keyring_cap*]
#   Ceph caps for the user.
#
# [*public_port*]
#   Which port to bind cinder. Default: 8776
#
# [*rbd_user*]
#   The user who connect to ceph for rbd operations. Default: cinder.
#   Note: A string "client_" will be prepended to the $rbd_user for actual
#   username configured on cephx
#
# [*volume_nofile*]
#   Number of open files to be configured in limits.conf
#

class rjil::cinder (
  $ceph_mon_key,
  $rpc_backend             = 'zmq',
  $rpc_zmq_bind_address    = '*',
  $rpc_zmq_contexts        = 1,
  $rpc_zmq_matchmaker      = 'oslo.messaging._drivers.matchmaker_ring.MatchMakerRing',
  $rpc_zmq_port            = 9501,
  $ceph_keyring_file_owner = 'cinder',
  $ceph_keyring_path       = '/etc/ceph/keyring.ceph.client.cinder_volume',
  $ceph_keyring_cap        = 'mon "allow r" osd "allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images"',
  $rbd_user                = 'cinder',
  $public_port             = 8776,
  $admin_email             = 'root@localhost',
  $server_name             = 'localhost',
  $localbind_host          = '127.0.0.1',
  $localbind_port          = 18776,
  $ssl                     = false,
  $volume_nofile           = 10240,
  $rewrites                = undef,
  $headers                 = undef,
  $use_default_quota_class = false,
) {

  ######################## Service Blockers and Ordering
  #######################################################

  ##
  # Adding service blocker for mysql which make sure mysql is avaiable before
  # database configuration.
  ##

  ensure_resource( 'rjil::service_blocker', 'master.mysql', {})
  Rjil::Service_blocker['master.mysql'] -> Cinder_config<| title == 'database/connection' |>

  ##
  # service blocker to stmon before mon_config to be run.
  # Mon_config must be run on all ceph client nodes also.
  # Also mon_config should be setup before cinder_volume to be started,
  #   as ceph configuration is required cinder_volume to function.
  ##

  ensure_resource('rjil::service_blocker', 'stmon', {})
  Rjil::Service_blocker['stmon']  ->
  Class['rjil::ceph::mon_config'] ->
  Class['::cinder::volume']

  include rjil::apache

  Service['cinder-api'] -> Service['httpd']

  ##
  # Ceph backend causing lot of open sockets to ceph osds, so increasing
  # number of openfiles
  ##
  file {'/etc/init/cinder-volume.conf':
    ensure  => file,
    owner   => 'root',
    mode    => '0644',
    content => template('rjil/upstart/cinder-volume.conf.erb'),
    notify  => Service['cinder-volume'],
  }
  ##
  # Cinder module dont have bind port parameter, so adding here for now.
  ##

  cinder_config { 'DEFAULT/osapi_volume_listen_port': value => $localbind_port }

  ##
  # Cinder default quotas read from the config file.

  cinder_config { 'DEFAULT/use_default_quota_class': value => $use_default_quota_class }

  ## Configure apache reverse proxy
  apache::vhost { 'cinder':
    servername      => $server_name,
    serveradmin     => $admin_email,
    port            => $public_port,
    ssl             => $ssl,
    docroot         => '/usr/lib/cgi-bin/cinder',
    error_log_file  => 'cinder.log',
    access_log_file => 'cinder.log',
    proxy_pass      => [ { path => '/', url => "http://${localbind_host}:${localbind_port}/"  } ],
    rewrites        => $rewrites,
    headers         => $headers,
  }

  ##
  # Adding order to run Ceph::Auth after cinder, this is because,
  # ceph::auth need the user to own the keyring file which is installed by
  # cinder
  ##

  Class['::cinder'] ->
  Ceph::Auth['cinder_volume']

  ##
  # class cinder will install cinder packages which create user cinder, which is
  # required before File[/var/log/cinder-manage.log] work.
  # Unless cinder is the owner for cinder-manage.log, "cinder-manage db sync"
  # which follows Cinder_config<| title == 'database/connection' |> will fail
  # So adding appropriate ordering.
  ##

  File['/var/log/cinder/cinder-manage.log'] ->
  Cinder_config<| title == 'database/connection' |>

  #######################################################

  ##
  # Below configuration (which are similar to oslo zmq configuration) are
  # required in case of zmq backend.
  ##

  if $rpc_backend == 'zmq' {
    cinder_config {
      'DEFAULT/rpc_zmq_bind_address': value => $rpc_zmq_bind_address;
      'DEFAULT/ring_file':            value => '/etc/oslo/matchmaker_ring.json';
      'DEFAULT/rpc_zmq_port':         value => $rpc_zmq_port;
      'DEFAULT/rpc_zmq_contexts':     value => $rpc_zmq_contexts;
      'DEFAULT/rpc_zmq_ipc_dir':      value => '/var/run/openstack';
      'DEFAULT/rpc_zmq_matchmaker':   value => $rpc_zmq_matchmaker;
      'DEFAULT/rpc_zmq_host':         value => $::hostname;
    }
  }

  ##
  # Making sure /var/log/cinder-manage.log is wriable by cinder user. This is
  # because, cinder module is running "cinder-manage db sync" as user cinder
  # which is failing as cinder dont have write permission to cinder-manage.log.
  ##

  ensure_resource('user','cinder',{ensure => present})

  file { '/var/log/cinder':
    ensure => directory
  }

  file {'/var/log/cinder/cinder-manage.log':
    ensure  => file,
    owner   => 'cinder',
    require => [ User['cinder'], File['/var/log/cinder'] ],
  }

  ##
  # Include rjil::ceph::mon_config because of dependancy.
  ##

  include rjil::ceph::mon_config
  include ::cinder
  include ::cinder::api
  include ::cinder::glance
  include ::cinder::scheduler
  include ::cinder::volume
  include ::cinder::volume::rbd
  include ::cinder::quota

  class { 'rjil::cinder::backup':
    ceph_mon_key => $ceph_mon_key,
  }

  ##
  # Add ceph keyring for cinder_volume. This is required cinder to connect to
  # ceph.
  ##

  ::ceph::auth {'cinder_volume':
    mon_key      => $ceph_mon_key,
    client       => $rbd_user,
    file_owner   => $ceph_keyring_file_owner,
    keyring_path => $ceph_keyring_path,
    cap          => $ceph_keyring_cap,
  }

  ##
  # Add ceph configuration for cinder_volume. This is required to find keyring
  # path while connecting to ceph as cinder_volume.
  ##
  ::ceph::conf::clients {'cinder_volume':
    keyring => $ceph_keyring_path,
  }

  ##
  # There are cross dependencies betweeen cinder_volume and cinder_scheduler.
  #   Consul service for cinder_volume will only check the process.
  # Also both cinder-volume and cinder-scheduler dont listen to a port.
  # NOTE: Because of the cross dependency between cinder-volume and
  # cinder-scheduler, it take two puppet runs to configure matchmaker entry for
  # cinder-scheduler (cinder-scheduler will not start in the first puppet run
  # because of the lack of cinder-volume matchmaker entry
  #
  ##

  ## Add tests for cinder api and registry
  include rjil::test::cinder

  rjil::test::check { 'cinder':
    address => $::cinder::api::bind_host,
    port    => $public_port,
    ssl     => $ssl,
  }

  rjil::jiocloud::consul::service { 'cinder':
    tags          => ['real'],
    port          => $public_port,
  }

  rjil::test::check { 'cinder-volume':
    type => 'proc',
  }

  rjil::jiocloud::consul::service { 'cinder-volume': }

  rjil::test::check { 'cinder-scheduler':
    type => 'proc',
  }

  rjil::jiocloud::consul::service { 'cinder-scheduler': }

  rjil::test::check { 'cinder-backup':
    type => 'proc',
  }

  rjil::jiocloud::consul::service { 'cinder-backup': }

  $cinder_logs = ['cinder-api',
                  'cinder-scheduler',
                  'cinder-volume',
                  'cinder-manage',
                  ]
  rjil::jiocloud::logrotate { $cinder_logs:
    logdir => '/var/log/cinder'
  }
}
