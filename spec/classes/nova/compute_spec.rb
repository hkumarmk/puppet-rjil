require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::nova::compute' do

  let :facts do
    {
      :operatingsystem  => 'Debian',
      :osfamily         => 'Debian',
      :concat_basedir   => '/tmp',
      :hostname         => 'node1',
      :ipaddress        => '10.1.0.10',
    }
  end

  let :hiera_data do
    {
      'rjil::ceph::mon_config::mon_config'               => 'foo',
      'nova::network::neutron::neutron_admin_password'   => 'pw',
      'ceph::conf::fsid'                                 => 'fsid',
      'rjil::nova::compute::rbd::ceph_mon_key'           => 'key',
      'rjil::nova::compute::rbd::cinder_rbd_secret_uuid' => '6d6502c1-1148-4994-8b85-0f1436b5d3f6',
      'nova::compute::ironic::keystone_password'         => 'secret'
    }
  end

  context 'with defaults' do

    it 'it should deploy libvirt with rbd config' do
      [
        'rjil::test::compute',
        'rjil::nova::zmq_config',
        'nova::client',
        'nova',
        'nova::compute',
        'nova::compute::neutron',
        'nova::compute::libvirt',
        'rjil::nova::compute::rbd',
        'rjil::nova::logrotate::manage'
      ].each do |x|
        should contain_class(x)
      end

      should contain_rjil__jiocloud__logrotate('nova-compute') \
        .with_logdir('/var/log/nova/')

      should contain_exec('rm_virbr0').with(
        {
          :command => 'virsh net-destroy default && virsh net-undefine default',
          :path    => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin',
          :onlyif  => 'virsh -q net-list | grep -q default' 
        }
      )

      should contain_package('python-six').with_ensure('latest')

      should contain_package('ethtool')

      should contain_rjil__jiocloud__consul__service('nova-compute').with(
        {
          :port          => 0,               
          :check_command => "sudo nova-manage service list | grep 'nova-compute.*node1.*enabled.*:-)'",
          :interval      => '120s',
        }
      )

      should contain_file('/etc/init/disable-gro.conf').with(
        {
          :source => 'puppet:///modules/rjil/disable-gro.conf',
          :owner  => 'root',  
          :group  => 'root',  
          :mode   => '0644'
        }
      )

      should contain_exec('disable-gro').with(
        {
          :command     => 'true ; cd /sys/class/net ; for x in *; do ethtool -K $x gro off || true; done',
          :path        => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin',
          :refreshonly => true
        }
      )

      should contain_package('libvirt').that_comes_before('Exec[rm_virbr0]')

      should contain_file_line('apparmor_deny_read_lttng').with(
        {
          :path    => '/etc/apparmor.d/abstractions/libvirt-qemu',
          :line    => '  deny /run/shm/lttng* r,',
          :require => 'Package[libvirt]',
          :notify  => 'Service[apparmor]',
        }
      )

    end
  end

  context 'with ironic' do

    let :params do
      {
        :compute_driver => 'ironic',
      }
    end

    it 'should deploy with ironic' do

      should contain_class('nova::compute::ironic')

      should_not contain_class('nova::compute::neutron')

      should_not contain_class('rjil::nova::compute::rbd')

      should_not contain_package('libvirt')

    end
  end

end
