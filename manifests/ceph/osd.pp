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
# [*disks*]
#    A comma separated list of all disks to be used as osds. There are two
#    custom facts added to support auto detecting this:
#
#    $::blankorcephdisks - All disks which are either ceph or blank disks
#    $::nonsystem_blankorcephdisks - Nonsystem disks which are either ceph or
#    blank disks. It use /dev/disk/by-path/ to detect non-system disks. Usually
#    baremetal system would have some system disks which are connected to
#    builtin controllers and disks connected to JBODs which are connected
#    through pci disk controllers.
#
#
# [*disk_exceptions*]
#    An array to configure any disks to be ignored from disks.
#
# [*osd_journal_size*]
#    size of journal in GB
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
# [*initialize*]
#   Initialize the disks by setup the disks like partitioning and formatting
#the disks
#
#

class rjil::ceph::osd (
  $mon_key                  = undef,
  $disks                    = $::osd_disks,
  $disk_exceptions          = undef,
  $osd_journal_type         = 'filesystem',
  $osd_journal_size         = 10,
  $storage_cluster_if       = eth1,
  $storage_cluster_address  = undef,
  $public_address           = undef,
  $public_if                = eth0,
  $autogenerate             = false,
  $autodisk_size            = 10,
  $initialize               = false,
) {

  if (! $initialize) and (! $mon_key) {
    fail('mon_key need to be specified unless initializing the osd sisks')
  }

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

    if $osd_journal_size > $autodisk_size/4 {
      fail("Your journal size ${osd_journal_size} should not be greater than your autodisk_size/${::processorcount} ${autodisk_size}/${::processorcount}.")
    }
    $osd_journal_size_orig = $osd_journal_size
    $autodisk_size_4k = $autodisk_size*1000000/4

    if $initialize {
      exec { 'make_disk_file':
        command => "dd if=/dev/zero of=/var/lib/ceph/disk-1 bs=4k \
                    count=${autodisk_size_4k}",
        unless  => 'test -e /var/lib/ceph/disk-1',
        timeout => 600,
        require => Package['ceph'],
      }
      Exec['attach_loop'] -> ::Ceph::OSD::Disk_setup['/dev/loop0']
    } else {
      Exec['attach_loop'] -> ::Ceph::OSD::Device['/dev/loop0']
    }

    exec {'attach_loop':
      command => 'losetup /dev/loop0 /var/lib/ceph/disk-1',
      unless  => 'losetup /dev/loop0',
    }

    $osds_orig = ['loop0']

  } else {
    $disks_array = split($disks,',')
    $disk_exceptions_array = split($disk_exceptions,',')
    $osds_orig = difference($disks_array,$disk_exceptions_array)
    $osd_journal_size_orig = $osd_journal_size
  }

  ##
  ## Add a prefix /dev/ to all disk devices
  ##

  $osd_disks = regsubst($osds_orig,'^([\w\d].*)$','/dev/\1',G)

  ##
  # Do the disk setup, if initialize is true, i.e on initial start.
  ##
  if $initialize {
    notice( " osds JOURNAL SIZE: $osd_journal_size_orig")
    ::ceph::osd::disk_setup { $osd_disks:
      osd_journal_type => $osd_journal_type,
      osd_journal_size => $osd_journal_size_orig,
      autogenerate     => $autogenerate,
    }
  } else {
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
      osd_journal_type => $osd_journal_type,
      osd_journal_size => $osd_journal_size_orig,
      autogenerate     => $autogenerate,
    }

    ##
    # ceph admin keyring only created on mon nodes by ceph module, but it is
    # required on all ceph nodes, so adding it here to create the keyring on all
    # nodes where osds are hosted
    ##

    ceph::auth {'admin':
      mon_key      => $mon_key,
      keyring_path => '/etc/ceph/keyring',
      cap          => "mon 'allow *' osd 'allow *' mds 'allow'",
    }

    ##
    # Running ceph::key with fake secret with admin just to satisfy condition in ceph module
    # The condition in ::ceph module may need to be removed, after checking upstream code.
    ##

    ::ceph::key { 'admin':
      secret   => 'AQCNhbZTCKXiGhAAWsXesOdPlNnUSoJg7BZvsw==',
    }

    ##
    # Ceph osd validation check
    ##
    rjil::test::ceph_osd { $osds_orig: }

  }

  ## End of ceph_setup
}
