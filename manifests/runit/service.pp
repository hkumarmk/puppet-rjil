##
# Define rjil::runit::service
# Manage runit service scripts
##

define rjil::runit::service (
  $command,
  $pre_start       = [],
  $service_name    = $name,
  $enable          = true,
  $user            = undef,
  $group           = undef,
  $enable_log      = true,
  $logdir          = "/var/log/${name}",
  $log_size        = 1000000000,
  $log_max_files   = 30,
  $log_min_files   = 2,
  $log_rotate_time = 86400,
  $log_timestamp   = true,
) {

  include rjil::runit

  file {"/etc/sv/${service_name}":
    ensure  => 'directory',
    require => Package['runit'],
  }

  file {"/etc/sv/${service_name}/run":
      ensure  => file,
      mode    => '0750',
      content => template('rjil/runit/service/run.erb'),
      require => File["/etc/sv/${service_name}"],
  }

  if $enable_log {
    file {"/etc/sv/${service_name}/log":
      ensure => 'directory',
    }

    file {"/etc/sv/${service_name}/log/run":
      ensure  => file,
      mode    => '0750',
      content => template('rjil/runit/service/log_run.erb'),
      require => File["/etc/sv/${service_name}/log"],
    }

    file {"/etc/sv/${service_name}/log/config":
      ensure  => file,
      mode    => '0440',
      content => template('rjil/runit/service/log_config.erb'),
      require => File["/etc/sv/${service_name}/log"],
    }
  }

  if $enable {
    file {"/etc/service/${service_name}":
      ensure => 'link',
      target => "/etc/sv/${service_name}",
      require => File["/etc/sv/${service_name}"],
    }
  }

}
