###
## Class: rjil::contrail
###
class rjil::contrail::server (
  $enable_analytics = true,
  $enable_config    = true,
  $enable_control   = true,
  $enable_webui     = true,
  $enable_ifmap     = true,
) {

  ##
  # Added tests
  ##
  $config_tests = ['contrail-api.sh', 'contrail-discovery.sh',
                    'contrail-schema.sh']
  $control_tests = ['contrail-control.sh','contrail-dns.sh']

  $webui_tests   = ['contrail-webui-webserver.sh','contrail-webui-jobserver.sh']

  $analytics_tests  = [ 'contrail-analytics.sh' ]

  $ifmap_tests = 'ifmap.sh'

  ##
  # Conditionally enable tests and logrotation for enabled services
  ##
  if $enable_config {
    rjil::test {$config_tests:}
    $config_logs = ['api','discovery','schema','svc-monitor']
  } else {
    $config_logs = []
  }

  if $enable_control {
    rjil::test {$control_tests: }
    $control_logs = ['contrail-control']
  } else {
    $control_logs = []
  }

  if $enable_webui {
    rjil::test {$webui_tests: }
    $webui_logs = ['webserver','jobserver']
  } else {
    $webui_logs = []
  }

  if $enable_analytics {
    rjil::test {$analytics_tests:}
    $analytics_logs = ['contrail-analytic-api','contrail-collector',
                        'query-engine']
  } else {
    $analytics_logs = []
  }

  if $enable_ifmap {
    rjil::test {$ifmap_tests:}
  }
  class {'::contrail':
    enable_config    => $enable_config,
    enable_control   => $enable_control,
    enable_webui     => $enable_webui,
    enable_analytics => $enable_analytics,
    enable_ifmap     => $enable_ifmap,
  }

  $contrail_logs = split(inline_template("<%= (@config_logs + @control_logs +
                          @webui_logs + @analytics_logs).join(',') %>"),',')

  rjil::jiocloud::logrotate { $contrail_logs:
    logdir => '/var/log/contrail'
  }
  
  ##
  # The logs which support higher filesize need either a sighup or
  # a copytruncate to rotate properly (else the process will keep writing to
  # older logfile. Using copytruncate to minimize any potential issue w/ sighup
  ##

  $contrail_logs_copytruncate = ['contrail-control',
                                'contrail-dns',
                                'contrail-ifmap-server',
  ]
  
  rjil::jiocloud::logrotate { $contrail_logs_copytruncate:
    logdir       => '/var/log/contrail',
    copytruncate => true,
  }
  
  include rjil::contrail::logrotate::consolidate

  ##
  # Deleting the default config logrotates which conflict with our changes
  # The default configs have multiple logfiles in a single config which
  # conflicts with our daily files setup
  ##
  $contrail_logrotate_delete = ['contrail-config',
                                'contrail-config-openstack',
                                'contrail-analytics',
                                'ifmap-server',
                                ]
  rjil::jiocloud::logrotate { $contrail_logrotate_delete:
    ensure => absent
  }
  
}
