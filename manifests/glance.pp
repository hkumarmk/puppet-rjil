## Class: rjil::openstack::glance
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
class rjil::glance (
  $ceph_mon_key                   = undef,
  $backend                        = 'file',
  $rbd_user                       = 'glance',
  $ceph_keyring_file_owner        = 'glance',
  $ceph_keyring_path              = '/etc/ceph/keyring.ceph.client.glance',
  $ceph_keyring_cap               = 'mon "allow r" osd "allow class-read object_prefix rbd_children, allow rwx pool=images"',
  $admin_email                    = 'root@localhost',
  $server_name                    = 'localhost',
  $api_localbind_host             = '127.0.0.1',
  $api_localbind_port             = '19292',
  $api_public_port                = '9292',
  $registry_localbind_host        = '127.0.0.1',
  $registry_localbind_port        = '19191',
  $registry_public_address        = '127.0.0.1',
  $registry_public_port           = '9191',
  $ssl                            = false,
  $rewrites                       = undef,
  $headers                        = undef,
  $allow_upload_img_admin_only    = true,
  $service_manager                = undef,
  $service_registrator            = false,
  $db_hostname                    = undef,
) {

  ##
  # make sure log directory exist - this would be required in case of container
  # and the log volume is mounted from docker host.
  ##

  file {'/var/log/glance':
    ensure => 'directory',
    owner  => 'glance',
  }

  ##
  # runit can be used to supervise services. This is useful especially for
  # containers when you run multiple processes.
  ##
  if $service_manager == 'runit' {
    rjil::runit::service {'glance-api':
      command    => '/usr/bin/glance-api',
      enable_log => false,
      user       => 'glance',
    }

    rjil::runit::service {'glance-registry':
      command    => '/usr/bin/glance-registry',
      enable_log => false,
      user       => 'glance',
    }
    # use runit provider for services
    Service<| title == 'glance-api' |> {
      provider => 'runit',
    }

    Service<| title == 'glance-registry' |> {
      provider => 'runit',
    }
  }


  ## Add tests for glance api and registry
  class {'rjil::test::glance':
    ssl => $ssl,
  }

  # ensure that we don't even try to configure the
  # database connection until the service is up

  if $db_hostname {
    $db_sb_params = { service_hostname => $db_hostname }
  } else {
    $db_sb_params = {}
  }

  ensure_resource( 'rjil::service_blocker', 'mysql', $db_sb_params)

  Rjil::Service_blocker['mysql'] -> Glance_api_config<| title == 'database/connection' |>
  Rjil::Service_blocker['mysql'] -> Glance_registry_config<| title == 'database/connection' |>

  ## setup glance api
  include ::glance::api

  ## Setup glance registry
  include ::glance::registry

  include rjil::apache

  Service['glance-api'] -> Service['httpd']
  Service['glance-registry'] -> Service['httpd']

  ## Configure apache reverse proxy
  apache::vhost { 'glance-api':
    servername      => $server_name,
    serveradmin     => $admin_email,
    port            => $api_public_port,
    ssl             => $ssl,
    docroot         => '/usr/lib/cgi-bin/glance-api',
    error_log_file  => 'glance-api.log',
    access_log_file => 'glance-api.log',
    proxy_pass      => [ { path => '/', url => "http://${api_localbind_host}:${api_localbind_port}/"  } ],
    rewrites        => $rewrites,
    headers         => $headers,
  }

  apache::vhost { 'glance-registry':
    servername      => $server_name,
    serveradmin     => $admin_email,
    port            => $registry_public_port,
    ssl             => $ssl,
    docroot         => '/usr/lib/cgi-bin/glance-registry',
    error_log_file  => 'glance-registry.log',
    access_log_file => 'glance-registry.log',
    proxy_pass      => [ { path => '/', url => "http://${registry_localbind_host}:${registry_localbind_port}/"  } ],
    rewrites        => $rewrites,
    headers         => $headers,
  }

  rjil::jiocloud::logrotate { 'glance-api':
    logfile => '/var/log/glance/api.log'
  }

  rjil::jiocloud::logrotate { 'glance-registry':
    logfile => '/var/log/glance/registry.log'
  }

  if($backend == 'swift') {
    ## Swift backend
    include ::glance::backend::swift
  } elsif($backend == 'file') {
    # File storage backend
    include ::glance::backend::file
  } elsif($backend == 'rbd') {
    # Rbd backend
    include rjil::ceph
    include rjil::ceph::mon_config
    ensure_resource('rjil::service_blocker', 'stmon', {})
    Rjil::Service_blocker['stmon'] -> Class['rjil::ceph::mon_config'] ->
    Class['::glance::backend::rbd']
    Class['glance::api'] -> Ceph::Auth['glance_client']

    if ! $ceph_mon_key {
      fail("Parameter ceph_mon_key is not defined")
    }
    ::ceph::auth {'glance_client':
      mon_key      => $ceph_mon_key,
      client       => $rbd_user,
      file_owner   => $ceph_keyring_file_owner,
      keyring_path => $ceph_keyring_path,
      cap          => $ceph_keyring_cap,
    }

    ::ceph::conf::clients {'glance':
      keyring => $ceph_keyring_path,
    }

    include ::glance::backend::rbd
  } elsif($backend == 'cinder') {
    # Cinder backend
    include ::glance::backend::cinder
  } else {
    fail("Unsupported backend ${backend}")
  }

  rjil::test::check { 'glance':
    type    => 'http',
    address => 'localhost',
    port    => $api_public_port,
    ssl     => $ssl,
  }

  rjil::test::check { 'glance-registry':
    type    => 'tcp',
    address => $registry_localbind_host,
    port    => $registry_localbind_port,
  }


  ##
  # In case of running glance in container, there is one app called registrator
  # which can be used to automatically register/deregister the consul services
  # automatically as and when the container up/down. in which case no need to
  # use rjil::jiocloud::consul::service to register the service.
  ##
  if ! $service_registrator {
    rjil::jiocloud::consul::service { "glance":
      tags          => ['real'],
      port          => $::glance::api::bind_port,
    }

    rjil::jiocloud::consul::service { 'glance-registry':
      tags          => ['real'],
      port          => $::glance::registry::bind_port,
    }
  }

  file { "/etc/glance/policy.json":
    ensure  => file,
    owner   => 'root',
    mode    => '0644',
    content => template('rjil/glance_policy.erb'),
    notify  => Service['glance-api'],
  }
}
