#
# Classs rjil::rsyslog
#  Just starting rsyslog::server class here, independant services may use
#  rsyslog::snippet to create separate config files for them
#
class rjil::rsyslog {

  include ::rsyslog::server

  rjil::test::check { 'rsyslogd':
    type     => 'proc',
    consumer => 'validation',
  }

}
