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
  $vncproxy_bind_port   = 6080,
  $consul_check_interval= '10s',
  $default_floating_pool = 'public',
  $memcached_servers    = service_discover_dns('memcached.service.consul','ip'),
  $admin_email          = 'root@localhost',
  $server_name          = 'localhost',
  $localbind_host       = '127.0.0.1',
  $memcached_port       = 11211,
  $osapi_public_port    = 8774,
  $ec2_public_port      = 8773,
  $osapi_localbind_port = 18774,
  $ec2_localbind_port   = 18773,
  $ssl                  = false,
  $flavors              = {},
  $nova_auth            = {},
) {

# Tests
  include rjil::test::nova_controller
  class { 'rjil::test::nova_flavor':
    flavors => $flavors,
  }

  nova_config {
    'DEFAULT/default_floating_pool':      value => $default_floating_pool;
    'DEFAULT/osapi_compute_listen_port':  value => $osapi_localbind_port;
    'DEFAULT/ec2_listen_port':            value => $ec2_localbind_port;
  }

  include rjil::apache
  Service['nova-api'] -> Service['httpd']

  ## Configure apache reverse proxy
  apache::vhost { 'nova-osapi':
    servername      => $server_name,
    serveradmin     => $admin_email,
    port            => $osapi_public_port,
    ssl             => $ssl,
    docroot         => '/usr/lib/cgi-bin/nova-osapi',
    error_log_file  => 'nova-osapi.log',
    access_log_file => 'nova-osapi.log',
    proxy_pass      => [ { path => '/', url => "http://${localbind_host}:${osapi_localbind_port}/"  } ],
    headers         => [ 'set Access-Control-Allow-Origin "*"' ],
  }

  apache::vhost { 'nova-ec2api':
    servername      => $server_name,
    serveradmin     => $admin_email,
    port            => $ec2_public_port,
    ssl             => $ssl,
    docroot         => '/usr/lib/cgi-bin/nova-ec2api',
    error_log_file  => 'nova-ec2api.log',
    access_log_file => 'nova-ec2api.log',
    proxy_pass      => [ { path => '/', url => "http://${localbind_host}:${ec2_localbind_port}/"  } ],
    headers         => [ 'set Access-Control-Allow-Origin "*"' ],
  }

  ##
  # The problem with fail function is that, as funtions are evaluated on compile
  # time, the execution will fail during that time, so if the condition
  # evaluates a resource or outcome of a resource execution which create on the
  # same role/node will cause the execution always fail as the puppet execution
  # will never happen. So using a type here.
  ##

  if ! empty($memcached_servers) {
    $fail = false
  }

  runtime_fail {'fail_before_nova':
    fail    => $fail,
    message => 'Memcache serverlist cannot be empty',
  }

  ##
  # Adding service blocker for mysql which make sure mysql is available before
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
  Runtime_fail['fail_before_nova'] ->
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
  include ::nova::quota

  ##
  # Create flavors
  ##
  create_resources('nova_flavor', $flavors, {auth => $nova_auth})

  ##
  # Making sure /var/log/nova-manage.log is writable by nova user. This is
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

  rjil::test::check { 'nova':
    address => $::nova::api::api_bind_address,
    port    => $osapi_public_port,
    ssl     => $ssl,
  }

  rjil::jiocloud::consul::service {'nova':
    tags          => ['real'],
    port          => $osapi_public_port,
    interval      => $consul_check_interval,
  }

  rjil::test::check { 'nova-scheduler':
    type => 'proc',
  }

  rjil::jiocloud::consul::service {'nova-scheduler':
    interval      => $consul_check_interval,
  }

  rjil::test::check { 'nova-conductor':
    type => 'proc',
  }

  rjil::jiocloud::consul::service {'nova-conductor':
    interval      => $consul_check_interval,
  }

  rjil::test::check { 'nova-cert':
    type => 'proc',
  }

  rjil::jiocloud::consul::service { 'nova-cert':
    interval      => $consul_check_interval,
  }

  rjil::test::check { 'nova-consoleauth':
    type => 'proc',
  }

  rjil::jiocloud::consul::service { 'nova-consoleauth':
    interval      => $consul_check_interval,
  }

  rjil::jiocloud::consul::service {'nova-vncproxy':
    port          => $vncproxy_bind_port,
    tags          => ['real'],
    interval      => $consul_check_interval,
    check_command => "/usr/lib/nagios/plugins/check_http -H localhost -p $vncproxy_bind_port -u /vnc_auto.html",
  }

}
