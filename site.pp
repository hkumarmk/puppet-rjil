Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin/","/usr/local/sbin/" ] }

class base {
  # install users
  include rjil
  include rjil::jiocloud
  include rjil::system::apt
  include rjil::server
  realize (
    Rjil::Localuser['jenkins'],
    Rjil::Localuser['soren'],
  )
#  include rjil::system
}

node /etcd/ {
  include base

  if $::etcd_discovery_token {
    $discovery = true
  } else {
    $discovery = false
  }
  class { 'rjil::jiocloud::etcd':
    discovery       => $discovery,
    discovery_token => $::etcd_discovery_token
  }
}

node /openstackclient\d*/ {
  include base
  class { 'openstack_extras::repo::uca':
    release => 'juno'
  }
  class { 'openstack_extras::client':
    ceilometer => false,
  }
}

node /haproxy/ {
  include base
  include rjil::haproxy
  class { 'rjil::haproxy::openstack' :
    keystone_ips => '10.0.0.1',
  }

}

## Setup databases on db node
node /db\d*/ {
  include base
  include rjil::db
}

## Setup memcache on mc node
node /mc\d*/ {
  include base
  include rjil::memcached
}

node /^lb\d+/ {
  include rjil::system
} 

node /apache\d*/ {
  include base
  ## Configure apache reverse proxy
  include rjil::apache
  apache::vhost { 'nova-api':
    servername      => $::ipaddress_eth1,
    serveradmin     => 'root@localhost',
    port            => 80,
    ssl             => false,
    docroot         => '/var/www',
    error_log_file  => 'test.error.log',
    access_log_file => 'test.access.log',
    logroot         => '/var/log/httpd',
   #proxy_pass => [ { path => '/', url => "http://localhost:${nova_osapi_compute_listen_port}/"  } ],
  }

}

node /keystone/ {
  include base
  include rjil::memcached
  include rjil::db
  include rjil::keystone
}
