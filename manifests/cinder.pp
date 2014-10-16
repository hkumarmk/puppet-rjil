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
# [*bind_port*]
#   Which port to bind cinder. Default: 8776
#
# [*rbd_user*]
#   The user who connect to ceph for rbd operations. Default: cinder.
#   Note: A string "client_" will be prepended to the $rbd_user for actual
#   username configured on cephx
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
  $bind_port               = 8776,
) {

  ## Add tests for cinder api and registry
  include rjil::test::cinder

  rjil::profile { 'cinder': }

  ######################## Service Blockers and Ordering
  #######################################################

  ##
  # Adding service blocker for mysql which make sure mysql is avaiable before
  # database configuration.
  ##

  ensure_resource( 'rjil::service_blocker', 'mysql', {})
  Rjil::Service_blocker['mysql'] -> Cinder_config<| title == 'database/connection' |>

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
  include ::cinder::scheduler
  include ::cinder::volume
  include ::cinder::volume::rbd

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

  rjil::jiocloud::consul::service { 'cinder':
    tags          => ['real'],
    port          => $bind_port,
    check_command => "/usr/lib/nagios/plugins/check_http -I ${::cinder::api::bind_host} -p ${bind_port}"
  }

  rjil::jiocloud::consul::service { 'cinder-volume':
    port          => 0,
    check_command => '/usr/lib/nagios/plugins/check_procs -c 1:10 -C cinder-volume'
  }

  rjil::jiocloud::consul::service { 'cinder-scheduler':
    port          => 0,
    check_command => "sudo cinder-manage service list | grep 'cinder-scheduler.*${::hostname}.*enabled.*:-)'"
  }
}
