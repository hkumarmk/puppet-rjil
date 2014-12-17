#
# profile for configuring keystone role
#
class rjil::keystone(
  $admin_email            = 'root@localhost',
  $public_address         = '0.0.0.0',
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

  include rjil::test::keystone

  if $public_address == '0.0.0.0' {
    $address = '127.0.0.1'
  } else {
    $address = $public_address
  }

  rjil::jiocloud::consul::service { "keystone":
    tags          => ['real'],
    port          => 5000,
    check_command => "/usr/lib/nagios/plugins/check_http -I ${address} -p 5000"
  }

  rjil::jiocloud::consul::service { "keystone-admin":
    tags          => ['real'],
    port          => 35357,
    check_command => "/usr/lib/nagios/plugins/check_http -I ${address} -p 35357"
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

  if $ssl {
    include rjil::apache
  }

  class { '::keystone': enabled => false }

  class {'::keystone::wsgi::apache':
    ssl                         => false,
    keystone_wsgi_script_source => '/usr/lib/python2.7/dist-packages/keystone_wsgi/__init__.py',
    workers                     => 3,
  }

  if $ceph_radosgw_enabled {
    include rjil::keystone::radosgw
  }

  if $ssl {
    ## Configure apache reverse proxy
    apache::vhost { 'keystone':
      servername      => $public_address,
      serveradmin     => $admin_email,
      port            => $public_port,
      ssl             => $ssl,
      docroot         => '/usr/lib/cgi-bin/keystone',
      error_log_file  => 'keystone.log',
      access_log_file => 'keystone.log',
      proxy_pass      => [ { path => '/', url => "http://localhost:${public_port_internal}/"  } ],
    }

    ## Configure apache reverse proxy
    apache::vhost { 'keystone-admin':
      servername      => $public_address,
      serveradmin     => $admin_email,
      port            => $admin_port,
      ssl             => $ssl,
      docroot         => '/usr/lib/cgi-bin/keystone',
      error_log_file  => 'keystone.log',
      access_log_file => 'keystone.log',
      proxy_pass      => [ { path => '/', url => "http://localhost:${admin_port_internal}/"  } ],
    }
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
