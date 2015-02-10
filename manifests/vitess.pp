#
# Class: rjil::vitess
#
class rjil::vitess {

  Class['vitess'] ->
  Class['vitess::vtctld'] ->
  Class['vitess::mysql'] ->
  Class['vitess::vttablet'] ->
  Class['vitess::vtgate']

  class {'::vitess': }
  include ::vitess::vtctld
  include ::vitess::mysql
  include ::vitess::vttablet
  include ::vitess::vtgate

}
