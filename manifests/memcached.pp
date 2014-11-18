### class: rjil::memcache
class rjil::memcached {

  ## Setup test code
  ## FIXME: memcached monitor is not installed with nagios-plugins packages
  ###       This need to be installed separately.
  ###       Currently this just check the process, need to be fixed.

  ## Create test script
  rjil::test { 'memcached.sh': }

  ## Call memcached class
  include '::memcached'

  rjil::jiocloud::consul::service {'memcached':
    port          => 11211,
    check_command => 'echo stats | nc localhost 11211 | grep -q uptime'
  }

}
