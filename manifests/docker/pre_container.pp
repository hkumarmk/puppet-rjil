#
#
#
#
class rjil::docker::pre_container (
  $ipc_dir         = '/var/run/openstack',
  $oslo_config_dir = '/etc/oslo',
) {

  ##
  # Make sure zmq ipc_dir exist on the host before running the container which
  # need this directory to be shared.
  ##
  file {[$ipc_dir, $oslo_config_dir]:
    ensure => 'directory',
  }
}
