class rjil::jiocloud::consul($config_hash) {
  include dnsmasq

  dnsmasq::conf { 'consul':
    ensure  => present,
    content => 'server=/consul/127.0.0.1#8600',
  }

  class { '::consul':
    install_method => 'package',
    ui_package_name => 'consul-web-ui',
    ui_package_ensure => 'absent',
    bin_dir => '/usr/bin',
    config_hash => $config_hash,
  } ~>
  exec { "reload-consul":
    command     => "/usr/bin/consul reload",
    refreshonly => true
  }

  ##
  # Some check_scripts need root access to run them. So adding consul in sudoers
  # list. For now adding all commands, later this may need to be changed (like
  # only allow running commands in /usr/lib/jiocloud/tests or so)
  ##

  ::sudo::conf { 'consul':
    content  => "#Managed By Puppet\nconsul ALL=(ALL) NOPASSWD: ALL",
  }
}
