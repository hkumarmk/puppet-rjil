#
# Class: rjil::test::nova_flavor
#   Adding tests for nova flavor
#

class rjil::test::nova_flavor(
  $flavors = []
) {

  include rjil::test::base

  file { "/usr/lib/jiocloud/tests/nova_flavor.sh":
    content => template("rjil/tests/nova_flavor.sh.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

}
