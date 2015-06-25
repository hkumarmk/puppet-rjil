## Class: rjil::system
## Purpose: to group all system level configuration together.

class rjil::system(
  $proxies                       = {},
  $dhclient_override_domain_name = undef,
) {

  ##
  ## It is decided to keep all devices in UTC timezone
  ## This will keep all our systems in single timezone even if we have servers
  ## outside
  ##    and in case we might have to get any external providers' services
  ##

  include ::timezone

  include rjil::system::apparmor
  include rjil::system::apt
  include rjil::system::accounts
  include rjil::system::metrics

  ensure_packages(['molly-guard'])

  ##
  # override domain name in dhclient
  ##
  if $dhclient_override_domain_name {
    file_line {$dhclient_override_domain_name:
      path => '/etc/dhcp/dhclient.conf',
      line => "supersede domain-name \"${dhclient_override_domain_name}\";",
      match => '^supersede\s+domain-name.*',
    }
  }

  ## Setup tests
  rjil::test {'check_timezone.sh':}

  Anchor['rjil::system::start'] -> Class['::timezone'] -> Anchor['rjil::system::end']
  contain rjil::system::ntp

  ## apt and accounts have circular dependancy, so making both of them dependant to anchors
  anchor { 'rjil::system::start':
    before => [Class['rjil::system::apt'],Class['rjil::system::accounts']],
  }
  anchor { 'rjil::system::end':
    require => [Class['rjil::system::apt'],Class['rjil::system::accounts']],
  }

  ##
  ## Added security banner messages
  ##

  $issue = [ '/etc/issue.net','/etc/issue' ]

  file { $issue:
    ensure        => file,
    owner         => root,
    group         => root,
    mode          => '0644',
    source        => "puppet:///modules/${module_name}/_etc_issue",
  }

  create_resources(rjil::system::proxy, $proxies)

  ##
  # Add domain search in resolvconf.
  # This is required to get matchmaker working - matchmaker ring driver need the
  # hostname without domain name to be resolved.
  ##

  file_line {'domain_search':
    path  => '/etc/resolvconf/resolv.conf.d/base',
    line  => 'search node.consul service.consul',
    match => 'search .*'
  }

  exec {'resolvconf':
    command     => 'resolvconf -u',
    refreshonly => true,
    subscribe   => File_line['domain_search'],
  }

  ##
  # autocompletion of hostnames for ssh and host commands.
  # TODO: this will remove the autocompletion for commandline options, which
  # need to be fixed.
  ##
  file { '/etc/bash_completion.d/host_complete':
    ensure        => file,
    owner         => root,
    group         => root,
    mode          => '0644',
    source        => "puppet:///modules/${module_name}/bash_completion.d_host_complete"
  }

  file { '/etc/securetty':
    mode => '0600'
  }

  sysctl::value {
    'net.ipv4.conf.all.accept_redirects':        value => 0;
    'net.ipv4.conf.default.accept_redirects':    value => 0;
    'net.ipv4.conf.all.secure_redirects':        value => 0;
    'net.ipv4.conf.default.secure_redirects':    value => 0;
    'net.ipv4.conf.default.accept_source_route': value => 0;
    'net.ipv4.conf.all.send_redirects':          value => 0;
    'net.ipv4.conf.default.send_redirects':      value => 0;
  }
}
