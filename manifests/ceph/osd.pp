#
# Class: rjil::ceph::osd
#
# == Parameters
#
# [*osd_journal_type*]
#   OSD Jounal types. Valid types are
#     first_partition -> first partition of the data disk,
#     filesystem -> journal directory under individual disk filesystem,
#
# [*osds*]
#    An Array of all disks to be used as osds
#
# [*autodetect*]
#    Automatically detect all blank disks and use them for ceph OSDs
#
# [*disk_exceptions*]
#    An array to configure any disks to be ignored from autodetected disks.
#
# [*osd_journal_size*]
#    size of journal
#
# [*storage_cluster_if*]
#    storage cluster interface
#
# [*storage_address*]
#    Optional storage cluster address, if not specified, this will be detected
#    from storage_cluster_if
#
# [*public_if*]
#    Public or storage access interface
#
# [*public_address*]
#    Optional public address, if not specified, this will be detected from
#    storage_cluster_if
#
# [*autogenerate*]
#   Generate a loopback disk for testing
#
# [*autodisk_size*]
#   Size of auto generated disk in GB. Minimum size required is 10GB in order
#   ceph to work smoothly.
# Note: both autogenerate and autodisk_size is only required while testing in
# dev machines or Vagrant.
#

class rjil::ceph::osd (
  $osds                     = [],
  $autodetect               = false,
  $disk_exceptions          = [],
  $osd_journal_type         = 'first_partition',
  $osd_journal_size         = 10,
  $storage_cluster_if       = eth1,
  $storage_cluster_address  = undef,
  $public_address           = undef,
  $public_if                = eth0,
  $autogenerate             = false,
  $autodisk_size            = 10,
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

  ##
  ## Fix for ceph being hang because of memory fragmentation
  ##

  sysctl::value { 'vm.dirty_background_ratio':
    value => 5,
  }

  exec { 'cleanup_caches':
    command => '/bin/sync && /bin/echo 1 > /proc/sys/vm/drop_caches',
    onlyif => "awk 'BEGIN {s=0} /DMA32|Normal/ { if \
                (\$9+\$10+\$11+\$12+\$13+\$14+\$15 < 100) {s=1} } END { \
                 print s }' /proc/buddyinfo | grep '1'",
  }

  ##
  ## Detect all blank disks (use $::blankorcephdisks facter) if autodetect is
  ##   enabled.
  ##  Disks to be used is difference of $blankorcephdisks and disk_exceptions
  ##
  ## If autogenerate is enabled, a loopback disk with size $autodisk_size GB
  ##   created, and will be used as OSD.

  if $autogenerate {

    ##
    # ceph will not work smoothly if autodisk_size is less than 10GB,
    # So adding a fail if autodisk_size is less than 10GB
    ##
    if $autodisk_size < 10 {
      fail("Autodisk size must be at least 10GB (current size: ${autodisk_size})")
    }

    ##
    ## fix osd_journal_size to autodisk_size/4 if not less than that.
    ##

    if $osd_journal_size > $autodisk_size/4 {
      warning("Configured OSD journal size (${osd_journal_size}) is less than Disk size (${autodisk_size}), reverting to 2GB")
      $osd_journal_size_orig = 2
    } else {
      $osd_journal_size_orig = $osd_journal_size
    }
    $autodisk_size_4k = $autodisk_size*1000000/4
    exec { 'make_disk_file':
      command => "dd if=/dev/zero of=/var/lib/ceph/disk-1 bs=4k \
                  count=${autodisk_size_4k}",
      unless  => 'test -e /var/lib/ceph/disk-1',
      timeout => 600,
      require => Package['ceph'],
    }

    exec {'attach_loop':
      command => 'losetup /dev/loop0 /var/lib/ceph/disk-1',
      unless  => 'losetup /dev/loop0',
      require => Exec['make_disk_file'],
      before  => ::Ceph::OSD::Device['/dev/loop0']
    }
    $osds_orig = ['loop0']

#    fail("osds_orig: $osds_orig")
  } elsif $autodetect {
    $disks = split($::blankorcephdisks,',')
    $osds_orig = difference($disks,$disk_exceptions)
    $osd_journal_size_orig = $osd_journal_size
  } else {
    $osds_orig = $osds
    $osd_journal_size_orig = $osd_journal_size
  }
  ##
  ## Add a prefix /dev/ to all disk devices
  ##

  $osd_disks = regsubst($osds_orig,'^([\w\d].*)$','/dev/\1',G)


  ##
  ## Add ceph osd configuration
  ##
  class { '::ceph::osd' :
    public_address => $public_address_orig,
    cluster_address => $storage_cluster_address_orig,
  }

  ##
  ##  Add all osd_disks to ceph
  ##
  ::ceph::osd::device { $osd_disks:
    osd_journal_type  => $osd_journal_type,
    osd_journal_size  => $osd_journal_size_orig,
    autogenerate     => $autogenerate,
  }

  ##
  ## Running ceph::key with fake secret with admin just to satisfy condition in ceph module
  ## The condition in ::ceph module may need to be removed, after checking upstream code.
  ##

  ::ceph::key { 'admin':
    secret   => 'AQCNhbZTCKXiGhAAWsXesOdPlNnUSoJg7BZvsw==',
  }
  ## End of ceph_setup
}
