#
# Class: rjil::nova::controller
#   To setup nova controller
#
# == Parameters
#
# [*api_bind_port*]
#   Nova api bind port. Default: 8774
#
# [*vncproxy_bind_port*]
#   Nova vncproxy bind port. Default: 6080
#
# [*memcached_servers*]
#   Array of memcached servers
#
# [*memcached_port*]
#   Memcached server port. Default: 11211
#
class rjil::nova::controller (
  $api_bind_port        = 8774,
  $vncproxy_bind_port   = 6080,
  $consul_check_interval= '120s',
  $memcached_servers    = service_discover_dns('memcached.service.consul','ip'),
  $memcached_port       = 11211,
) {

# Tests
  include rjil::test::nova_controller

  ##
  # Adding service blocker for mysql which make sure mysql is avaiable before
  # database configuration.
  ##

  ensure_resource( 'rjil::service_blocker', 'mysql', {})
  Rjil::Service_blocker['mysql'] ->
  Nova_config<| title == 'database/connection' |>

  ##
  # memcached service blocker to make sure memcached is up before memcached
  # configuration in nova.
  ##
  ensure_resource('rjil::service_blocker','memcached',{})
  Rjil::Service_blocker['memcached'] ->
  Nova_config<| title == 'DEFAULT/memcached_servers' |>

  ##
  # db_sync fail if nova-manage.log is writable by nova user, so making the file
  # with appropriate ownership before setup database configuration.
  ##

  File['/var/log/nova/nova-manage.log'] ->
  Nova_config<| title == 'database/connection' |>

  ##
  # Make sure nova services refreshed on matchmakerring config changes.
  ##

  Matchmakerring_config<||> ~> Exec['post-nova_config']

  ##
  # python-six(1.8.x) is required which are not handled in the package.
  # So handling here.
  ##
  ensure_resource('package','python-six',{ensure => latest})

  Package['python-six'] -> Class['nova::api']


  ##
  # Python-memcache is a dependancy to use memcache, but not handled in the
  # package. Installing that package.
  ##
  package {'python-memcache': ensure => installed }

  Package['python-memcache'] -> Class['nova']

  if empty($memcached_servers) {
    fail("Memcache servers cannot be empty")
  }

  $memcache_url = split(inline_template('<%= @memcached_servers.map{ |ip| "#{ip}:#{@memcached_port}" }.join(",") %>'),',')

  include ::rjil::nova::zmq_config
  include ::nova::client
  class {'::nova':
    memcached_servers => $memcache_url
  }
  include ::nova::scheduler
  include ::nova::api
  include ::nova::network::neutron
  include ::nova::conductor
  include ::nova::cert
  include ::nova::consoleauth
  include ::nova::vncproxy

  ##
  # Making sure /var/log/nova-manage.log is wriable by nova user. This is
  # because, nova module is running "nova-manage db sync" as user nova
  # which is failing as nova dont have write permission to nova-manage.log.
  ##

  ensure_resource('user','nova',{ensure => present})

  ensure_resource('file','/var/log/nova', {ensure => directory})

  file {'/var/log/nova/nova-manage.log':
    ensure  => file,
    owner   => 'nova',
  }

  ##
  # Consul service registration
  # nova api bind port is not there in nova::api class param, so adding that
  # param in rjil::nova::controller.
  ##

  rjil::jiocloud::consul::service {'nova':
    tags          => ['real'],
    port          => $api_bind_port,
    check_command => "/usr/lib/nagios/plugins/check_http -I ${::nova::api::api_bind_address} -p ${api_bind_port}",
    interval      => $consul_check_interval,
  }

  rjil::jiocloud::consul::service {'nova-scheduler':
    port          => 0,
    check_command => "sudo nova-manage service list | grep 'nova-scheduler.*${::hostname}.*enabled.*:-)'",
    interval      => $consul_check_interval,
  }

  rjil::jiocloud::consul::service {'nova-conductor':
    port          => 0,
    interval      => $consul_check_interval,
    check_command => "sudo nova-manage service list | grep 'nova-conductor.*${::hostname}.*enabled.*:-)'"
  }

  rjil::jiocloud::consul::service {'nova-cert':
    port          => 0,
    interval      => $consul_check_interval,
    check_command => "sudo nova-manage service list | grep 'nova-cert.*${::hostname}.*enabled.*:-)'"
  }

  rjil::jiocloud::consul::service {'nova-consoleauth':
    port          => 0,
    interval      => $consul_check_interval,
    check_command => "sudo nova-manage service list | grep 'nova-consoleauth.*${::hostname}.*enabled.*:-)'"
  }

  rjil::jiocloud::consul::service {'nova-vncproxy':
    port          => $vncproxy_bind_port,
    tags          => ['real'],
    interval      => $consul_check_interval,
    check_command => "/usr/lib/nagios/plugins/check_http -H localhost -p $vncproxy_bind_port -u /vnc_auto.html",
  }

}
