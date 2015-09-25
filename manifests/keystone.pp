#
# profile for configuring keystone role
#
#
# [*service_manager*]
#   Service manager, by default it is using system specific service manager, say
#   for ubuntu it is upstart. But in case of docker container, docker doesnt
#   support upstart service scripts, so have to use different one, another
#   supported service manager is 'runit'.
# [*service_registrator*]
#   In case of docker container, there is an app called registrator which
#   register/deregister services to consul (and other service discovery tools)
#   as the container come up/down. So in case service_registrator is
#   true, no need to do define consul services using
#   rjil::jiocloud::consul::service. Default is false.
#

class rjil::keystone(
  $admin_email            = 'root@localhost',
  $userapi_address        = '0.0.0.0',
  $server_name            = 'localhost',
  $userapi_port           = '443',
  $userapi_port_internal  = '5000',
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
  $rewrites               = undef,
  $headers                = undef,
  $service_manager        = undef,
  $service_registrator    = false,
) {

  if $userapi_address == '0.0.0.0' {
    $address = '127.0.0.1'
  } else {
    $address = $userapi_address
  }


  ##
  # Create validation check for keystone
  ##
  include rjil::test::keystone

  Rjil::Test::Check {
    ssl     => $ssl,
    address => $address,
  }

  rjil::test::check { 'keystone':
    port => $userapi_port,
  }

  rjil::test::check { 'keystone-admin':
    port => $admin_port,
  }

  ##
  # In case of running keystone in container, there is one app called registrator
  # which can be used to automatically register/deregister the consul services
  # automatically as and when the container up/down. in which case no need to
  # use rjil::jiocloud::consul::service to register the service.
  ##
  if ! $service_registrator {
    rjil::jiocloud::consul::service { "keystone":
      tags          => ['real'],
      port          => 5000,
    }

    rjil::jiocloud::consul::service { "keystone-admin":
      tags          => ['real'],
      port          => 35357,
    }
  }

  ##
  # runit can be used to supervise services. This is useful especially for
  # containers when you run multiple processes.
  ##
  if $service_manager == 'runit' {
    rjil::runit::service {'keystone':
      command => '/usr/bin/keystone-all',
      user    => 'keystone',
      enable_log => false,  # no need to log from runit as keystone already log all under /var/log/keystone/keystone-all.log
    }

    # use runit provider for keystone service
    Service<| title == 'keystone' |> {
      provider => 'runit',
    }
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
    port            => $userapi_port,
    ssl             => $ssl,
    docroot         => '/usr/lib/cgi-bin/keystone',
    error_log_file  => 'keystone.log',
    access_log_file => 'keystone.log',
    proxy_pass      => [ { path => '/', url => "http://localhost:${userapi_port_internal}/"  } ],
    rewrites        => $rewrites,
    headers         => $headers,
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
    rewrites        => $rewrites,
    headers         => $headers,
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

  $keystone_logs = ['keystone-manage',
                    'keystone-all',
                    ]
  rjil::jiocloud::logrotate { $keystone_logs:
    logdir => '/var/log/keystone'
  }

  ##
  # Create keystone objects
  ##
  include rjil::keystone::objects

}
