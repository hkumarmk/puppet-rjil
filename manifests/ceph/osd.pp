###Class: rjil::ceph
class rjil::ceph::osd (
  $osds,
  $osd_journal_type = 'first_partition', ## first_partition -> first partition of the data disk, filesystem -> journal directory under individual disk filesystem, /dev/sdx (device name) - separate journal disk (not implemented)
  $osd_journal_size = 10, ## Journal size in GiB, only numaric part, no unit, only applicable for 'first_partition'
  $storage_cluster_if      = eth0,
  $storage_cluster_address = undef,
  $public_address          = undef,
  $public_if               = eth1,
)
{

  if $storage_cluster_address {
    $storage_cluster_address_orig = $storage_cluster_address
  } elsif $storage_cluster_if {
    $storage_cluster_address_orig = inline_template("<%= scope.lookupvar('ipaddress_' + @storage_cluster_if) %>")
  }

  if $public_address {
    $public_address_orig = $public_address
  } elsif $public_if {
    $public_address_orig = inline_template("<%= scope.lookupvar('ipaddress_' + @public_if) %>")
  }

  ## Fix for ceph being hang because of memory fragmentation
  sysctl::value { "vm.dirty_background_ratio":
    value => 5,
  }

  exec { "cleanup_caches":
    command => "/bin/sync && /bin/echo 1 > /proc/sys/vm/drop_caches",
    onlyif => "awk 'BEGIN {s=0} /DMA32|Normal/ { if (\$9+\$10+\$11+\$12+\$13+\$14+\$15 < 100) {s=1} } END { print s }' /proc/buddyinfo | grep '1'",
  }


  ## Add ceph osds
  class { '::ceph::osd' :
      public_address => $public_address_orig,
      cluster_address => $storage_cluster_address_orig,
    }

    ::ceph::osd::device { $osds:
      osd_journal_type => $osd_journal_type,
      osd_journal_size  => $osd_journal_size
    }




## Running ceph::key with fake secret with admin just to satisfy condition in ceph module
## The condition in ::ceph module may need to be removed, after checking upstream code.
  ::ceph::key { 'admin':
    secret   => 'AQCNhbZTCKXiGhAAWsXesOdPlNnUSoJg7BZvsw==',
  }
  ## End of ceph_setup
}
