Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin/","/usr/local/sbin/" ], logoutput => true }
Apt::Source<||> { tag => 'package' }
Package<||> { tag => 'package' }
include rjil::system::apt
