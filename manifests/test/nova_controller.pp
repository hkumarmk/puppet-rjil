#
# Class: rjil::test::nova_controller
#   Adding tests for nova services
#

class rjil::test::nova_controller {

  include openstack_extras::auth_file

  $scripts = ['nova-api.sh','nova-scheduler.sh','nova-conductor.sh','nova-cert.sh','nova-vncproxy.sh','nova-consoleauth.sh']

  rjil::test { $scripts: }

}
