#
# site.pp for db
#
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin/","/usr/local/sbin/" ], logoutput => true }

Package<||> { tag => 'package' }
Apt::Source<||> { tag => 'package' }

Service<| title == 'mysqld' |> {
  ensure => stopped,
  enable => false,
}

include rjil::db
