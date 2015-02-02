#
# Class: rjil::vitess
#
class rjil::vitess {

  Class['vitess'] ->
  Class['vitess::vtctld'] ->
  Class['vitess::mysql'] ->
  Class['vitess::vttablet']

  class {'::vitess': }
  include ::vitess::vtctld
  include ::vitess::mysql
  include ::vitess::vttablet

#  contain rjil::zookeeper

}
