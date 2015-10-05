#
# Class: rjil::jiocloud
# This is called by rjil::base for setting up of repositories, consul role, puppet and system upgrade related stuff
#

class rjil::jiocloud (
  $consul_role = 'agent'
) {

  if ! member(['agent', 'server', 'bootstrapserver'], $consul_role) {
    fail("consul role should be agent|server|bootstrapserver, not ${consul_role}")
  }

  include rjil::system::apt

  # ensure that python-jiocloud is installed before
  # consul and dnsmasq. This is b/c these packages
  # can introduce race conditions that effect dns
  # and we cannot currently recover if we fail to
  # install python-jiocloud
  ensure_resource('package','python-six', { ensure => 'latest' })

  package {'docker-engine':
    ensure => 'installed'
  }

  package { 'python-jiocloud':
    before => [Package['dnsmasq'], Package['consul']]
  }

  if $consul_role == 'bootstrapserver' {
    include rjil::jiocloud::consul::cron
  } else {
    $addr = "${::consul_discovery_token}.service.consuldiscovery.linux2go.dk"
    dns_blocker {  $addr:
      try_sleep     => 10,
      tries         => 100,
      before        => Service['consul'],
    }
  }

  include "rjil::jiocloud::consul::${consul_role}"

  include rjil::jiocloud::consul::base_checks

  include rjil::puppet_config

  include rjil::puppet_run

}
