## Class rjil::system::apt
## Purpose: configure apt sources
class rjil::system::apt (
  $enable_ubuntu     = true,
  $enable_puppetlabs = true,
  $enable_ceph       = true,
  $enable_rustedhalo = true,
) {

  ## two settings to be overrided here in hiera
  ## apt::purge_sources_list: true, apt::purge_sources_list_d: true
  include ::apt

  ## All package operations should follow apt::source
  Apt::Source<||> -> Package<||>

  ## reduce the priority of rustedhalo repository so that all openstack packages
  ##   will use ubuntu repos for now. The packages in rustedhalo are not stable.

  apt::pin { "reduce_priority_rustedhalo":
    origin   => 'jiocloud.rustedhalo.com',
    priority => 100,
  }

  Apt::Pin<||> -> Package<||>

  if $enable_puppetlabs {
    include puppet::repo::puppetlabs
  }

  if $enable_ceph {
    include rjil::system::apt::repo::ceph
  }

  if $enable_rustedhalo {
    include rjil::system::apt::repo::rustedhalo
  }

  if $enable_ubuntu {
    include rjil::system::apt::repo::ubuntu
  }

}

