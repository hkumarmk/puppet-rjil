##
# Class: rjil::nova::compute
##
class rjil::nova::compute (
  $ceph_mon_key,
  $cinder_rbd_secret_uuid,
  $ceph_keyring_file_owner    = 'nova',
  $ceph_keyring_path          = '/etc/ceph/keyring.ceph.client.cinder_volume',
  $ceph_keyring_cap           = 'mon "allow r" osd "allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images"',
  $rbd_user                   = 'cinder_volume',
  $nova_snapshot_image_format = 'qcow2',
  $consul_check_interval      = '120s',
) {

  #
  # Add tests for nova compute
  ##

  include rjil::test::compute


  ##
  # service blocker to stmon before mon_config to be run.
  # Mon_config must be run on all ceph client nodes also.
  # Also mon_config should be setup before cinder_volume to be started,
  #   as ceph configuration is required cinder_volume to function.
  ##

  ensure_resource('rjil::service_blocker', 'stmon', {})
  Rjil::Service_blocker['stmon']  ->
  Class['rjil::ceph::mon_config'] ->
  Ceph::Conf::Clients['cinder_volume'] ->
  Exec['secret_set_value_cinder_volume']


  ##
  # This will fix the failure on puppet first run.
  ##
  Concat['/etc/ceph/ceph.conf'] ->
  Exec['secret_set_value_cinder_volume']

  Class['::nova'] ->
  Ceph::Auth['cinder_volume']

  Package['libvirt'] ->
  Exec['secret_define_cinder_volume']

  Package['libvirt'] ->
  Exec['rm_virbr0']

  ensure_resource('package','python-six', { ensure => 'latest' })

  ##
  # Hardcoding private/public ipaddress/interface will not work in case of
  # compute node, the IP address will be moved to vhost0 So adding a variable
  # to get interface details by running the function first_interface_with_ip.
  ##

  $usable_ipaddress = first_interface_with_ip('ipaddress',"${private_interface},vhost0")


  include ::ceph::conf
  include rjil::ceph::mon_config
  include rjil::nova::zmq_config
  include ::nova::client
  include ::nova
  class {'::nova::compute':
    vncserver_proxyclient_address => $usable_ipaddress
  }
  include ::nova::compute::libvirt
  include ::nova::compute::neutron
  include ::nova::network::neutron

  ##
  # Add ceph keyring for cinder_volume. This is required cinder to connect to
  # ceph.
  ##

  ::ceph::auth {'cinder_volume':
    mon_key      => $ceph_mon_key,
    client       => $rbd_user,
    file_owner   => $ceph_keyring_file_owner,
    keyring_path => $ceph_keyring_path,
    cap          => $ceph_keyring_cap,
  }


  ##
  # Remove libvirt default nated network
  ##
  exec { 'rm_virbr0':
    command => "virsh net-destroy default && virsh net-undefine default",
    path    => "/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin",
    onlyif  => "virsh -q net-list | grep -q default" ,
  }

  ##
  # Add ceph configuration for cinder_volume. This is required to find keyring
  # path while connecting to ceph as cinder_volume.
  ##
  ::ceph::conf::clients {'cinder_volume':
    keyring => $ceph_keyring_path,
  }


  exec { "secret_define_cinder_volume":
    command => "echo \"<secret ephemeral='no'
            private='no'><uuid>$cinder_rbd_secret_uuid</uuid><usage
            type='ceph'><name>client.cinder_volume</name></usage></secret>\" | \
            virsh secret-define --file /dev/stdin",
    unless => "virsh secret-list | egrep $cinder_rbd_secret_uuid",
  }

  exec { "secret_set_value_cinder_volume":
    command => "virsh secret-set-value --secret $cinder_rbd_secret_uuid \
                --base64 $(ceph --name mon. --key ${ceph_mon_key} auth get-key \
                client.cinder_volume)",
    unless => "ceph --name mon. --key ${ceph_mon_key} auth get-key \
                client.cinder_volume | grep \"$(virsh -q secret-get-value \
                $cinder_rbd_secret_uuid)\"",
    require => Exec["secret_define_cinder_volume"],
    notify => Service ['libvirt'],
  }

  rjil::jiocloud::consul::service {'nova-compute':
    port          => 0,
    check_command => "sudo nova-manage service list | grep 'nova-compute.*${::hostname}.*enabled.*:-)'",
    interval      => $consul_check_interval,
  }

  ensure_resource(package, 'ethtool')

  Package <| name == 'ethtool' |> ->
  file { "/etc/init/disable-gro.conf":
    source => 'puppet:///modules/rjil/disable-gro.conf',
    owner  => 'root',
    group  => 'root',
    mode   => '0644'
  } ~>
  exec { "disable-gro":
    command     => 'true ; cd /sys/class/net ; for x in *; do ethtool -K $x gro off || true; done',
    path        => "/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin",
    refreshonly => true
  }
}
