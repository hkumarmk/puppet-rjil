##
# Class: rjil::runit
# manifests to handle runit http://smarden.org/runit/
##
class rjil::runit {

  package {'runit':
    ensure => installed,
  }

  $sv_dirs = ['/etc/sv', '/etc/service']

  file {$sv_dirs:
    ensure  => 'directory',
    require => Package['runit'],
  }

}
