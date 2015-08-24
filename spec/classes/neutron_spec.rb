require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::neutron' do
  let :facts do
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
      'neutron::rabbit_user'                        => 'rabbit',
      'neutron::rabbit_password'                    => 'rabbit',
      'neutron::core_plugin'                        => 'coreplugin',
      'neutron::service_plugins'                    => ['serviceplugin1'],
      'neutron::quota::quota_driver'                => 'contraildriver',
      'rjil::neutron::api_extensions_path'          => 'extensionspath',
      'rjil::neutron::service_provider'             => 'serviceprovider',
      'rjil::neutron::server_name'                  => 'neutron.server',
    }
  end

  context 'with defaults' do
    it  do
      should contain_file('/usr/lib/jiocloud/tests/service_checks/neutron.sh').with_content(
        /check_http -H 0\.0\.0\.0 -p 9696/
      )

      should contain_file('/usr/lib/jiocloud/tests/service_checks/neutron.sh').with_content(
        /check_http -H 127.0.0.1 -p 19696/
      )

      should contain_file('/usr/lib/jiocloud/tests/floating_ip.sh')
      should contain_package('python-six').with_ensure('latest').that_comes_before('Class[neutron::server]')
      should contain_class('neutron')
      should contain_class('neutron::server')
      should contain_class('neutron::quota')
      should contain_neutron_config('DEFAULT/api_extensions_path').with_value('extensionspath')
      should contain_neutron_config('service_providers/service_provider').with_value('serviceprovider')

      should contain_rjil__jiocloud__consul__service('neutron').with({
        'tags'      => ['real'],
        'port'      => 9696,
        'check_command' => "/usr/lib/jiocloud/tests/service_checks/neutron.sh",
      })

      should contain_exec('empty_neutron_conf').with({
        'command'     => 'mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak_puppet',
        'refreshonly' => true,
        'subscribe'   => 'Package[neutron-server]',
      })

      should contain_class('rjil::apache')

      should contain_apache__vhost('neutron').with({
        'servername'      => 'neutron.server',
        'serveradmin'     => 'root@localhost',
        'port'            => 9696,
        'ssl'             => false,
        'docroot'         => '/usr/lib/cgi-bin/neutron',
        'error_log_file'  => 'neutron.log',
        'access_log_file' => 'neutron.log',
        'proxy_pass'      => [ { 'path' => '/', 'url' => 'http://127.0.0.1:19696/'  } ],
      })

    end
  end
  context 'with ssl' do
    let :params do
      {'ssl' => true}
    end
    it do
      should contain_file('/usr/lib/jiocloud/tests/service_checks/neutron.sh').with_content(
        /check_http -S -H 0\.0\.0\.0 -p 9696/
      )
      should contain_file('/usr/lib/jiocloud/tests/service_checks/neutron.sh').with_content(
        /check_http -S -H 127.0.0.1 -p 19696/
      )

      should contain_apache__vhost('neutron').with_ssl(true)
    end
  end
end
