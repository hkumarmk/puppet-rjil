#
# Class: rjil::neutron
#
class rjil::neutron (
  $api_extensions_path = undef,
  $service_provider    = undef,
) {

  ##
  # Rjil tests
  ##
  include rjil::test::neutron

  ##
  # Database connection is not required for neutron
  ##

  Neutron_config<| title == 'database/connection' |> {
    ensure => absent
  }

  ##
  # Subscribe neutron-server to contrailplugin.ini
  ##

  File['/etc/neutron/plugins/opencontrail/ContrailPlugin.ini'] ~>
    Service['neutron-server']

  ##
  # Python-six version >= 1.8.x is required for neutron server, and not handled in package. So
  # installing it prior to neutron-server.
  ##

  Package['python-six'] -> Class['::neutron::server']

  include ::neutron
  include ::neutron::server
  include rjil::contrail::server

  package {'python-six':
    ensure  => latest,
  }

  ##
  # neutron_config is making multiple entries for service_provider
  # I see that neutron_config just change the value of all entries there. This
  # is causig problem as there are multiple entries for service_provider in
  # default configuration (one for lb and one for VPN)
  # Because of this neutron server is not getting started. As a workaround, just
  # purging default configuration file before configuration.
  #
  # NOTE: neutron_config doesnt support multiple enties of same configuration.
  # It may have to use different method (or to extend neutron_config) to setup
  # service_provider later when it is going to have mulitple service providers.
  ##
  exec {'empty_neutron_conf':
    command     => 'mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak_puppet',
    refreshonly => true,
    subscribe   => Package['neutron-server'],
  }

  Exec['empty_neutron_conf'] -> Neutron_config<||>

  ##
  # Below configs are not there in neutron module, so adding here for now.
  # These are required for contrail configuration.
  ##

  if $api_extensions_path {
    neutron_config {'DEFAULT/api_extensions_path':
      value => $api_extensions_path,
    }
  }


  if $service_provider {
    neutron_config { 'service_providers/service_provider':
      value => $service_provider
    }
  }

  rjil::jiocloud::consul::service { 'neutron':
    tags      => ['real'],
    port      => 9696,
    check_command => "/usr/lib/nagios/plugins/check_http -I 127.0.0.1 -p 9696",
  }

}
