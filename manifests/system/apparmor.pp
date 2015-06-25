##
# This class provide code for apparmor management
##
class rjil::system::apparmor {

  package { 'apparmor':
    ensure => present,
  }

  service { 'apparmor':
    ensure => running,
  }
}
