#
# profile for configuring keystone role
#
class rjil::keystone(
  $admin_email            = 'root@localhost',
  $public_address         = '0.0.0.0',
  $server_name            = 'localhost',
  $public_port            = '443',
  $public_port_internal   = '5000',
  $admin_port             = '35357',
  $admin_port_internal    = '35357',
  $ssl                    = false,
  $ceph_radosgw_enabled   = false,
  $cache_enabled          = false,
  $cache_config_prefix    = 'cache.keystone',
  $cache_expiration_time  = '600',
  $cache_backend          = undef,
  $cache_backend_argument = undef,
  $disable_db_sync        = false,
) {

  Service['keystone'] -> Service['httpd']

  if $public_address == '0.0.0.0' {
    $address = '127.0.0.1'
  } else {
    $address = $public_address
  }

  Rjil::Test::Check {
    ssl     => $ssl,
    address => $address,
  }

  rjil::test::check { 'keystone':
    port => $public_port,
  }

  rjil::test::check { 'keystone-admin':
    port => $admin_port,
  }

  rjil::jiocloud::consul::service { "keystone":
    tags          => ['real'],
    port          => 5000,
  }

  rjil::jiocloud::consul::service { "keystone-admin":
    tags          => ['real'],
    port          => 35357,
  }

  # ensure that we don't even try to configure the
  # database connection until the service is up
  ensure_resource( 'rjil::service_blocker', 'mysql', {})
  Rjil::Service_blocker['mysql'] -> Keystone_config['database/connection']

  if $disable_db_sync {
    Exec <| title == 'keystone-manage db_sync' |> {
      unless => '/bin/true'
    }
  }

  include rjil::apache
  include ::keystone

  if $ceph_radosgw_enabled {
    include rjil::keystone::radosgw
  }

  ## Configure apache reverse proxy
  apache::vhost { 'keystone':
    servername      => $server_name,
    serveradmin     => $admin_email,
    port            => $public_port,
    ssl             => $ssl,
    docroot         => '/usr/lib/cgi-bin/keystone',
    error_log_file  => 'keystone.log',
    access_log_file => 'keystone.log',
    proxy_pass      => [ { path => '/', url => "http://localhost:${public_port_internal}/"  } ],
    headers         => [ 'set Access-Control-Allow-Origin "*"' ],
  }

  ## Configure apache reverse proxy
  apache::vhost { 'keystone-admin':
    servername      => $server_name,
    serveradmin     => $admin_email,
    port            => $admin_port,
    ssl             => $ssl,
    docroot         => '/usr/lib/cgi-bin/keystone',
    error_log_file  => 'keystone.log',
    access_log_file => 'keystone.log',
    proxy_pass      => [ { path => '/', url => "http://localhost:${admin_port_internal}/"  } ],
    headers         => [ 'set Access-Control-Allow-Origin "*"' ],
  }

  ## Keystone cache configuration
  if $cache_enabled {
    keystone_config {
      'cache/enabled':          value => 'True';
      'cache/config_prefix':    value => $cache_config_prefix;
      'cache/expiration_time':  value => $cache_expiration_time;
      'cache/cache_backend':    value => $cache_backend;
      'cache/backend_argument': value => $cache_backend_argument;
    }
  }

  Class['rjil::keystone'] -> Rjil::Service_blocker<| title == 'keystone-admin' |>

}
