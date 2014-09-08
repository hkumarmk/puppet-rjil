###Class: rjil::ceph
class rjil::ceph (
  $mon_config, ## a hash of mon hostname and ip address
  $fsid,
  $mon_initial_members = undef,
  $admin_key = undef,
  $keyring  = '/etc/ceph/keyring',
  $auth_type  = 'cephx',
  $storage_cluster_if      = eth0,
  $storage_cluster_network = undef,
  $public_network          = undef,
  $public_if               = eth1,
  $osd_journal_type   = 'first_partition',
) {


  anchor {'rjil::ceph::start':
    before => Class['::ceph::conf']
  }
  anchor {'rjil::ceph::end':
    require => Class['::ceph::conf']
  }

  ## Here is set of ceph nagios plugins (https://github.com/valerytschopp/ceph-nagios-plugins).
  ## Ideally these plugins should be installed - we should make a deb package and install as part of initializing test
  ## Just copied one script from this for now, which needs to be fixed.
  rjil::test { 'ceph_health.py': }

  if $storage_cluster_network {
    $storage_cluster_network_orig = $storage_cluster_network
  } elsif $storage_cluster_if {
    $sc_net   = inline_template("<%= scope.lookupvar('network_' + @storage_cluster_if) %>")
    $sc_mask  = inline_template("<%= scope.lookupvar('netmask_' + @storage_cluster_if) %>")
    if $sc_mask {
      $sc_cidr  = netmask2cidr($sc_mask)
      $storage_cluster_network_orig = "${sc_net}/${sc_cidr}"
    }
  }

  if $public_network {
    $public_network_orig = $public_network
  } elsif $public_if {
    $pub_net   = inline_template("<%= scope.lookupvar('network_' + @public_if) %>")
    $pub_mask  = inline_template("<%= scope.lookupvar('netmask_' + @public_if) %>")
    if $pub_mask {
      $pub_cidr  = netmask2cidr($pub_mask)
      $public_network_orig = "${pub_net}/${pub_cidr}"
    }
  }
  if $mon_initial_members {
    $mon_initial_members_orig = $mon_initial_members
  } else {
    $mon_initial_members_orig = join(keys($mon_config),',')
  }
  ## run base ceph installation and config  which is to be setup
  ## on all systems which need ceph to be called

  ## Create ceph configuration directory
  ## This should go to ::ceph class, will be moved
  ##     if not there in thier master

  file {'/etc/ceph':
    ensure => directory,
  }

  ## Generage basic ceph configuration
  ## This is required to be exist on both ceph servers and clients

  class { '::ceph::conf':
    fsid             => $fsid,
    auth_type        => $auth_type,
    cluster_network  => $storage_cluster_network_orig,
    public_network   => $public_network_orig,
    mon_init_members => $mon_initial_members_str,
    osd_journal_type => $osd_journal_type,
    require          => File['/etc/ceph'],
  }

  ## specify mon cluster details
  if is_hash($mon_config) {
    create_resources(::ceph::conf::mon_config,$mon_config)
  } else {
    fail("Incorrect ceph mon definition: $mon_config")
  }

}
