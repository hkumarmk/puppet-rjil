require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::cinder' do
  let:facts do
    {
      :operatingsystem  => 'Debian',
      :osfamily         => 'Debian',
      :concat_basedir   => '/tmp',
      :hostname         => 'node1',
    }
  end
  let :hiera_data do
    {
      'cinder::api::registry_host'                  => '10.1.1.100',
      'cinder::api::auth_host'                      => '10.1.1.10',
      'cinder::api::keystone_password'              => 'pass',
      'cinder::api::mysql_module'                   => '2.3',
      'openstack_extras::auth_file::admin_password' => 'pw',
      'cinder::rpc_backend'                         => 'zmq',
      'cinder::scheduler::scheduler_driver'         => 'cinder.scheduler.simple.SimpleScheduler',
      'cinder::volume::rbd::rbd_pool'               => 'volumes',
      'cinder::volume::rbd::rbd_user'               => 'cinder_volume',
      'cinder::volume::rbd::rbd_secret_uuid'        => '26f3bfcf-7acd-40ec-948d-62b12cd14901',
      'cinder::volume::rbd::volume_tmp_dir'         => '/tmp',
      'rjil::cinder::ceph_mon_key'                  => 'AQBRSfNSQNCMAxAA/wSNgHmHwzjnl2Rk22P4jA==',
      'rjil::cinder::rbd_user'                      => 'cinder_volume',
      'rjil::ceph::mon_config::mon_config'          => ['1.1.1.1'],
      'cinder::api::bind_host'                      => '10.1.1.1',
    }
  end

  context 'with http' do
    it  do
      should contain_file('/usr/lib/jiocloud/tests/cinder-api.sh')
      should contain_file('/usr/lib/jiocloud/tests/cinder-volume.sh')
      should contain_file('/usr/lib/jiocloud/tests/cinder-scheduler.sh')
      should contain_rjil__profile('cinder')
      should contain_Cinder_config('database/connection').that_requires('Rjil::Service_blocker[mysql]')
      should contain_class('rjil::ceph::mon_config').that_requires('Rjil::Service_blocker[stmon]')
      should contain_class('cinder::volume').that_requires('Class[rjil::ceph::mon_config]')
      should contain_ceph__auth('cinder_volume').that_requires('Class[cinder]')
      should contain_cinder_config('DEFAULT/rpc_zmq_bind_address').with_value('*')
      should contain_cinder_config('DEFAULT/ring_file').with_value('/etc/oslo/matchmaker_ring.json')
      should contain_cinder_config('DEFAULT/rpc_zmq_port').with_value(9501)
      should contain_cinder_config('DEFAULT/rpc_zmq_contexts').with_value(1)
      should contain_cinder_config('DEFAULT/rpc_zmq_ipc_dir').with_value('/var/run/openstack')
      should contain_cinder_config('DEFAULT/rpc_zmq_matchmaker').with_value('oslo.messaging._drivers.matchmaker_ring.MatchMakerRing')
      should contain_cinder_config('DEFAULT/rpc_zmq_host').with_value('node1')
      should contain_class('rjil::ceph::mon_config')
      should contain_class('cinder')
      should contain_class('cinder::api')
      should contain_class('cinder::scheduler')
      should contain_class('cinder::volume')
      should contain_class('cinder::volume::rbd')
      should contain_ceph__auth('cinder_volume').with({
        'mon_key'      => 'AQBRSfNSQNCMAxAA/wSNgHmHwzjnl2Rk22P4jA==',
        'client'       => 'cinder_volume',
        'file_owner'   => 'cinder',
        'keyring_path' => '/etc/ceph/keyring.ceph.client.cinder_volume',
      })
      should contain_ceph__conf__clients('cinder_volume').with({
        'keyring' => '/etc/ceph/keyring.ceph.client.cinder_volume'
      })
      should contain_rjil__jiocloud__consul__service('cinder').with({
        'tags'          => ['real'],
        'port'          => 8776,
        'check_command' => "/usr/lib/nagios/plugins/check_http -I 10.1.1.1 -p 8776"
      })
      should contain_rjil__jiocloud__consul__service('cinder-volume').with({
        'port'          => 0,
        'check_command' => "/usr/lib/nagios/plugins/check_procs -c 1:10 -C cinder-volume"
      })
      should contain_rjil__jiocloud__consul__service('cinder-scheduler').with({
        'port'          => 0,
        'check_command' => "sudo cinder-manage service list | grep 'cinder-scheduler.*node1.*enabled.*:-)'"
      })
    end
  end
end
