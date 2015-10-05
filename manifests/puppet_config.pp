#
# Class rjil::puppet_config
#
class rjil::puppet_config {
  if ($::settings::default_manifest == './manifests') {
    $val = '/etc/puppet/manifests/site.pp'
  } else {
    $val = $::settings::default_manifest
  }

  ini_setting { 'default_manifest':
    path    => '/etc/puppet/puppet.conf',
    section => main,
    setting => default_manifest,
    value   => $val
  }

  ini_setting { 'templatedir':
    ensure  => absent,
    path    => "/etc/puppet/puppet.conf",
    section => 'main',
    setting => 'templatedir',
  }
 
  ini_setting { 'modulepath':
    ensure  => absent,
    path    => "/etc/puppet/puppet.conf",
    section => 'main',
    setting => 'modulepath',
  }
 
  ini_setting { 'manifestdir':
    ensure  => absent,
    path    => "/etc/puppet/puppet.conf",
    section => 'main',
    setting => 'manifestdir',
  }
}
