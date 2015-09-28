#
# Class rjil::system_container
#
class rjil::system_container (
  $check_address_facts = true,
) {
  include rjil::jiocloud
  #include rjil::system
  include rjil::jiocloud::dns
  include rjil::default_manifest

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

  if $check_address_facts {
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

}

