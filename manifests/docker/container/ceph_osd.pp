#
# A helper class to be used in rjil::docker::container_wrapper for setting up
# ceph osds. This will accept the disks (whole number of disks in the node) and
# call rjil::docker::container::ceph_osd::instance for individual disks which in
# fact create container per disk
#
class rjil::docker::container::ceph_osd (
  $container_params,
  $disks,
  $default_params = undef,
) {

  ##
  # Create osd containers per disk
  ##
  rjil::docker::container::ceph_osd::instance {$disks:
    container_params => $container_params,
    default_params   => $default_params,
  }
}
