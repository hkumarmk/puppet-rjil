require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::neutron::contrail' do
  let:facts do
    {
      :operatingsystem        => 'Debian',
      :operatingsystemrelease => '14.04',
      :osfamily               => 'Debian',
      :concat_basedir         => '/tmp',
      :hostname               => 'node1',
      :interfaces             => 'eth0,lo',
      :ipaddress_eth0         => '10.1.1.100',
      :lsbdistid              => 'ubuntu',
      :lsbdistcodename        => 'trusty',
      :processorcount         => '10',      
      :ipaddress              => '10.1.1.1',
    }
  end
  let :hiera_data do
    {
      'neutron::server::auth_host'                  => '10.1.1.10',
      'neutron::server::auth_password'              => 'pass',
      'openstack_extras::auth_file::admin_password' => 'pw',
      'contrail::keystone_host'                     => '10.1.1.1',
      'contrail::keystone_admin_token'              => 'token',
      'contrail::keystone_admin_password'           => 'pass',
      'contrail::keystone_auth_password'           => 'pass',
      'neutron::rabbit_password'                    => 'guest',
      'neutron::core_plugin'                        => 'coreplugin',
      'neutron::service_plugins'                    => ['serviceplugin1'],
      'neutron::quota::quota_driver'                => 'contraildriver',
      'rjil::neutron::api_extensions_path'          => 'extensionspath',
      'rjil::neutron::service_provider'             => 'serviceprovider',
    }
  end

  context 'with public cidr' do

    let :params do
      {
        'public_cidr'             => '1.1.1.0/24',
        'keystone_admin_password' => 'pass',
      }
    end

    it 'should configure public network' do

      should contain_neutron_network('public').with({
        'ensure'          => 'present',
        'router_external' => true
      })
      should contain_neutron_subnet('pub_subnet1').with({
        'ensure'       => 'present',
        'cidr'         => '1.1.1.0/24',
        'network_name' => 'public'
      })
      should contain_contrail_rt('default-domain:services:public').with({
        'ensure'             => 'present',
        'rt_number'          => 10000,
        'router_asn'         => 64512,
        'api_server_address' => 'real.neutron.service.consul',
        'admin_password'     => 'pass',
        'require'            => 'Neutron_network[public]',
      })
    end

  end

  context 'when public cidr has start/end set' do

    let :params do
      {
        'public_cidr'             => '1.1.1.0/24',
        'keystone_admin_password' => 'pass',
        'public_subnet_ip_start'  => '1.1.1.4',
        'public_subnet_ip_end'    => '1.1.1.14',
      }
    end
    it { should contain_neutron_subnet('pub_subnet1').with({
        'ensure'           => 'present',
        'cidr'             => '1.1.1.0/24',
        'network_name'     => 'public',
        'allocation_pools' => ['start=1.1.1.4,end=1.1.1.14'],
      })}

  end
end
