## Class: rjil::system
## Purpose: to group all system level configuration together.

class rjil::system {
  include rjil::system::apt
  include rjil::system::accounts

  ##
  ## rjil::system::ntp include ::ntp and add test code
  ##
  include rjil::system::ntp

  ## apt and accounts have circular dependancy, so making both of them dependant to anchors
  anchor { 'rjil::system::start':
    before => [Class['rjil::system::apt'],Class['rjil::system::accounts']],
  }
  anchor { 'rjil::system::end':
    require => [Class['rjil::system::apt'],Class['rjil::system::accounts']],
  }

  Anchor['rjil::system::start'] -> Class['rjil::system::ntp'] -> Anchor['rjil::system::end']

}
