## Class: rjil::openstack::glance
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
  $allow_upload_img_admin_only    = true
) {

  ## Add tests for glance api and registry
  class {'rjil::test::glance':
    ssl => $ssl,
  }

  # ensure that we don't even try to configure the
  # database connection until the service is up
  ensure_resource( 'rjil::service_blocker', 'master.mysql', {})
  Rjil::Service_blocker['master.mysql'] -> Glance_api_config<| title == 'database/connection' |>
  Rjil::Service_blocker['master.mysql'] -> Glance_registry_config<| title == 'database/connection' |>

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

  rjil::jiocloud::consul::service { "glance":
    tags          => ['real'],
    port          => $::glance::api::bind_port,
  }

  rjil::jiocloud::consul::service { 'glance-registry':
    tags          => ['real'],
    port          => $::glance::registry::bind_port,
  }

  file { "/etc/glance/policy.json":
    ensure  => file,
    owner   => 'root',
    mode    => '0644',
    content => template('rjil/glance_policy.erb'),
    notify  => Service['glance-api'],
  }
}
