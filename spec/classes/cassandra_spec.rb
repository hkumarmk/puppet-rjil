require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::cassandra' do

  let :hiera_data do
    {
      'rjil::cassandra::cluster_name' => 'testcluster',
      'rjil::cassandra::thread_stack_size' => 400,
    }
  end

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :lsbdistid       => 'ubuntu',
      :ipaddress       => '10.1.2.3',
      :processorcount  => 4,
    }
  end

  context 'with hieraconfig' do
    it do
      should contain_file('/usr/lib/jiocloud/tests/check_cassandra.sh')
      should contain_class('cassandra').with({
        'seeds'             => ['10.1.2.3'],
        'cluster_name'      => 'testcluster',
        'thread_stack_size' => 400,
        'version'           => '1.2.18-1',
        'package_name'      => 'dsc12',
      })
    end
  end

  context 'with parameters' do
     let :params do
      {
        :seeds        => ['10.1.2.1','10.1.2.2','10.1.2.3'],
        :cluster_name => 'test',
      }
    end
    it do
      should contain_class('cassandra').with({
        'seeds'             => ['10.1.2.1','10.1.2.2','10.1.2.3'],
        'cluster_name'      => 'test',
        'thread_stack_size' => 400,
        'version'           => '1.2.18-1',
        'package_name'      => 'dsc12',
      })
    end
  end
end
