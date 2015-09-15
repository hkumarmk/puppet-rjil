#
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin/","/usr/local/sbin/" ], logoutput => true }

node /^bootstrap\d+/ {
  include rjil::docker::host
}

node /^ocdb\d+/ {
  include rjil::docker::host
  include rjil::db::container
  include rjil::consul_service::db
#  include rjil::consul_service::memcached
#  include rjil::consul_service::keystone

}
