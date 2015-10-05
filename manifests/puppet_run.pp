#
#
#
class rjil::puppet_run {

  package { 'run-one':   
    ensure => present,   
  } 
    
  file { '/usr/local/bin/jiocloud-update.sh':
    source => 'puppet:///modules/rjil/update.sh',
    mode => '0755',
    owner => 'root',
    group => 'root'
  } 
    
  file { '/usr/local/bin/maybe-upgrade.sh':
    source => 'puppet:///modules/rjil/maybe-upgrade.sh',
    mode   => '0755',
    owner  => 'root',
    group  => 'root'
  } 
  cron { 'maybe-upgrade':
    command => 'run-one /usr/local/bin/maybe-upgrade.sh 2>&1 | logger',
    user    => 'root',
    require => Package['run-one'],
  } 

}
