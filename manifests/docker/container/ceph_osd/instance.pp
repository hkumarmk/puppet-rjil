#
# This type create individual containers by calling rjil::docker::container with
# appropriate parameters. This will help to create individual containers per
# ceph osds.
#
#
define rjil::docker::container::ceph_osd::instance (
  $container_params,
  $default_params,
  $disk           = $name,
  $container_name = "osd-${::hostname}-${name}"
) {

  ##
  # This will be used by the container to setup the osd - this will setup a fact
  # for osd_disks in container which will be used by rjil::ceph::osd to setup
  # osd on it.
  $extra_envvars = ["FACTER_osd_disks=${disk}"]

  ##
  # Detect the partitions available (which is created while initializing the
  # node (from userdata/vagrant).
  ##

  $disk_device = "/dev/${disk}"
  $part1 = inline_template("<%= File.exist?(@disk_device + '1')? @disk_device + '1' : nil%>")
  $part2 = inline_template("<%= File.exist?(@disk_device + '2')? @disk_device + '2' : nil%>")


  $devices = [$disk_device, $part1, $part2]

  $extra_params = merge($default_params, {extra_envvars => $extra_envvars, devices => $devices, privileged => true})

  create_resources('rjil::docker::container', {"${container_name}" => $container_params}, $extra_params)

}
