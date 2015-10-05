#
# Class rjil::base_host
#
class rjil::base_host () {
  include ::timezone
  include rjil::system::apt
  include rjil::system::accounts
  include logrotate::base
  include rjil::puppet_config
  include rjil::puppet_run


  package {'docker-engine':
    ensure => 'installed'
  }


  ##
  # New kind of ipaddress and interface facts (ipaddress and interface based on
  # subnet assigned to them) are raising new problem - in case
  # of a misconfiguration of subnets, those facts can return null values for
  # those facts. In that case, puppet run should explicitely fail to avoid the
  # system to go into invalid state.
  # NOTE: This code assume the fact is only used for private_address,
  # public_address, private_interface, public_interface. If in future those
  # facts used for anything else, they must be validated either here or in
  # appropriate code.
  ##

  if ! hiera('private_address') {
    fail("hiera data for 'private_address' is not known")
  } elsif ! hiera('private_interface') {
    fail("Hiera data for 'private_interface' is not known")
  } elsif ! hiera('public_address') {
    fail("hiera data for 'public_address' is not known")
  } elsif ! hiera('public_interface') {
    fail("Hiera data for 'public_interface' is not known")
  }

}

