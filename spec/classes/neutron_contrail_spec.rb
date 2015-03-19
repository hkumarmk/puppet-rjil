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
      'rjil::neutron::contrail::fip_pools'          => {
                                                          :public => {
                                                              :network_name => 'public_net',
                                                              :subnet_name  => 'pub_subnet',
                                                              :cidr         => '1.1.1.1/24',
                                                            }
                                                        }
    }
  end

  context 'with public cidr' do

    let :params do
      {
        'keystone_admin_password' => 'pass',
      }
    end

    it  do
      should contain_class('rjil::neutron')
      should contain_class('rjil::contrail::server')
      should contain_rjil__neutron__contrail__fip_pool('public')
    end
  end
end
