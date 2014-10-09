require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::ceph::mon' do

  let :hiera_data do
    {
      'rjil::ceph::mon::public_if'  => 'eth0',
      'rjil::ceph::mon::key'        => 'AQBXRgNSQNCMAxAA/wSNgHmHwzjnl2Rk22P4jA==',
      'rjil::ceph::fsid'            => '94d178a4-cae5-43fa-b420-8ae1cfedb7dc',
      'ceph::conf::fsid'            => '94d178a4-cae5-43fa-b420-8ae1cfedb7dc',
    }
  end

  let :facts do
    {
      'lsbdistid'       => 'ubuntu',
      'lsbdistcodename' => 'trusty',
      'osfamily'        => 'Debian',
      'interfaces'      => 'eth0,eth1',
      'ipaddress_eth0'  => '10.1.0.2',
      'concat_basedir'  => '/tmp/',
      'hostname'        => 'host1',
    }
  end
  context 'default resources' do
    it 'should contain default resources' do
      should contain_rjil__ceph__mon__mon_config('mon_config_host1').with({
        'public_if'        => 'eth0',
        'mon_service_name' => 'stmon.service.consul',
      })
      should contain_ceph__mon('host1').with({
        'monitor_secret'  => 'AQBXRgNSQNCMAxAA/wSNgHmHwzjnl2Rk22P4jA==',
        'mon_addr'        => '10.1.0.2',
      })
      should contain_ceph__osd__pool('volumes','backups','images').with({
        'num_pgs' => 128,
        'require' => 'Ceph::Mon[host1]',
      })
      should contain_file('/usr/lib/jiocloud/tests/check_ceph_mon.sh')
      should contain_rjil__jiocloud__consul__service('stmon').with({
        'port'          => 6789,
        'check_command' => '/usr/lib/jiocloud/tests/check_ceph_mon.sh'
      })
    end
  end
end
