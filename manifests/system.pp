## Class: rjil::system
## Purpose: to group all system level configuration together.

class rjil::system {
  include rjil::system::apt
  include rjil::system::accounts

  ## apt and accounts have circular dependancy, so making both of them dependant to anchors
  anchor { 'rjil::system::start':
    before => [Class['rjil::system::apt'],Class['rjil::system::accounts']],
  }
  anchor { 'rjil::system::end':
    require => [Class['rjil::system::apt'],Class['rjil::system::accounts']],
  }
}
