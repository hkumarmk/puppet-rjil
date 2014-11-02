require 'spec_helper'

describe 'rjil::openstack_zeromq' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :lsbdistid       => 'ubuntu',
      :ipaddress       => '10.1.2.3',
      :processorcount  => 4,
    }
  end

  context 'with defaults' do
    let :params do
      {
        :cinder_scheduler_nodes => {'as.example.com' => '1.1.1.1',
                                    'bs.example.com' => '1.1.1.2'},
        :cinder_volume_nodes    => {'av.example.com' => '1.1.1.1',
                                    'bv.example.com' => '1.1.1.2'},
        :nova_scheduler_nodes   => {'nsa.example.com' => '1.1.1.1',
                                    'nsb.example.com' => '1.1.1.2'},
        :nova_consoleauth_nodes => {'nca.example.com' => '1.1.1.1',
                                    'ncb.example.com' => '1.1.1.2'},
        :nova_conductor_nodes   => {'noa.example.com' => '1.1.1.1',
                                    'nob.example.com' => '1.1.1.2'},
        :nova_cert_nodes        => {'nea.example.com' => '1.1.1.1',
                                    'neb.example.com' => '1.1.1.2'},
        :nova_compute_nodes     => {'comupte.example.com' => '1.1.1.1'}
      }
    end
    it do
      should contain_host('as.example.com').with({
        'ip'            => '1.1.1.1',
        'host_aliases'  => 'as',
      })
      should contain_host('bs.example.com').with({
        'ip'            => '1.1.1.2',
        'host_aliases'  => 'bs',
      })
      should contain_host('av.example.com').with({
        'ip'            => '1.1.1.1',
        'host_aliases'  => 'av',
      })
      should contain_host('bv.example.com').with({
        'ip'            => '1.1.1.2',
        'host_aliases'  => 'bv',
      })
      should contain_host('nsa.example.com').with({
        'ip'            => '1.1.1.1',
        'host_aliases'  => 'nsa',
      })
      should contain_host('nsb.example.com').with({
        'ip'            => '1.1.1.2',
        'host_aliases'  => 'nsb',
      })
      should contain_host('nca.example.com').with({
        'ip'            => '1.1.1.1',
        'host_aliases'  => 'nca',
      })
      should contain_host('ncb.example.com').with({
        'ip'            => '1.1.1.2',
        'host_aliases'  => 'ncb',
      })
      should contain_host('noa.example.com').with({
        'ip'            => '1.1.1.1',
        'host_aliases'  => 'noa',
      })
      should contain_host('nob.example.com').with({
        'ip'            => '1.1.1.2',
        'host_aliases'  => 'nob',
      })
      should contain_host('nea.example.com').with({
        'ip'            => '1.1.1.1',
        'host_aliases'  => 'nea',
      })
      should contain_host('neb.example.com').with({
        'ip'            => '1.1.1.2',
        'host_aliases'  => 'neb',
      })
      should contain_class('openstack_zeromq').with({
        'cinder_scheduler_nodes' => ['as','bs'],
        'cinder_volume_nodes'    => ['av','bv'],
        'nova_scheduler_nodes'   => ['nsa','nsb'],
        'nova_consoleauth_nodes' => ['nca','ncb'],
        'nova_conductor_nodes'   => ['noa','nob'],
        'nova_cert_nodes'        => ['nea','neb'],
      })
    end
  end
end
