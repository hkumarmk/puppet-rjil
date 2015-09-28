#
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin/","/usr/local/sbin/" ], logoutput => true }

node /consul/ {
  include rjil::base_host
  include rjil::docker
#   notice('HI')
}

node default {
  include rjil::docker::host
}
