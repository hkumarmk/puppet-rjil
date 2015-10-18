Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin/","/usr/local/sbin/" ], logoutput => true }

Package<||> { tag => 'package' }
Apt::Source<||> { tag => 'package' }

include rjil::cinder
