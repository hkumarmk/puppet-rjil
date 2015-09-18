##
# Class: rjil::runit
# manifests to handle runit http://smarden.org/runit/
##
class rjil::runit {

  package {'runit':
    ensure => installed,
  }

}
