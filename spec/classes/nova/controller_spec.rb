require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::nova::controller' do
  let:facts do
    {
      :operatingsystemrelease => '14.04',
      :operatingsystem        => 'Debian',
      :osfamily               => 'Debian',
      :concat_basedir         => '/tmp',
      :hostname               => 'node1',
    }
  end
  let :hiera_data do
    {
      'nova::rpc_backend'                             => 'zmq',
      'nova::api::auth_host'                          => '10.1.1.10',
      'nova::api::admin_password'                     => 'pass',
      'nova::mysql_module'                            => '2.3',
      'nova::database_connection'                     => 'mysql://user:pass@dbhost/db',
      'nova::glance_api_servers'                      => 'glanceserver:9292',
      'nova::api::enabled'                            => true,
      'nova::scheduler::enabled'                      => true,
      'nova::conductor::enabled'                      => true,
      'nova::consoleauth::enabled'                    => true,
      'nova::cert::enabled'                           => true,
      'nova::vncproxy::enabled'                       => true,
      'nova::network::neutron::neutron_admin_password'=> 'neutron',
      'nova::network::neutron::neutron_url'           => 'http://neutronserver:9696',
      'nova::network::neutron::neutron_admin_auth_url'=> 'http://10.1.1.10:5000/v2.0',
      'nova::api::api_bind_address'                   => '0.0.0.0',
      'rjil::nova::controller::osapi_public_port'     => 100,
      'rjil::nova::controller::vncproxy_bind_port'    => 101,
      'openstack_extras::auth_file::admin_password'   => 'pw',
      'rjil::nova::controller::memcached_servers'     => ['10.2.2.1','10.2.2.2'],
      'rjil::nova::controller::server_name'           => 'nova.server',
    }
  end

  context 'without manage_flavors' do
    let :params do
      {
        :manage_flavors => false,
      }
    end

    it 'should not manage flavors' do
      should_not contain_nova_flavor

      should_not contain_rjil__test__nova_flavor
    end
  end

  context 'with http, defaults' do
    it  do
      should contain_class('rjil::apache')
      should contain_apache__vhost('nova-osapi').with(
        {
          'servername'      => 'nova.server',
          'serveradmin'     => 'root@localhost',
          'port'            => '100',
          'ssl'             => false,
          'docroot'         => '/usr/lib/cgi-bin/nova-osapi',
          'error_log_file'  => 'nova-osapi.log',
          'access_log_file' => 'nova-osapi.log',
          'proxy_pass'      => [ { 'path' => '/', 'url' => "http://127.0.0.1:18774/"  } ],
        }
      )

      should contain_apache__vhost('nova-ec2api').with(
        {
          'servername'      => 'nova.server',
          'serveradmin'     => 'root@localhost',
          'port'            => '8773',
          'ssl'             => false,
          'docroot'         => '/usr/lib/cgi-bin/nova-ec2api',
          'error_log_file'  => 'nova-ec2api.log',
          'access_log_file' => 'nova-ec2api.log',
          'proxy_pass'      => [ { 'path' => '/', 'url' => "http://127.0.0.1:18773/"  } ],
        }
      )

      should contain_file('/usr/lib/jiocloud/tests/nova-api.sh')
      should contain_file('/usr/lib/jiocloud/tests/nova-scheduler.sh')
      should contain_file('/usr/lib/jiocloud/tests/nova-cert.sh')
      should contain_file('/usr/lib/jiocloud/tests/nova-conductor.sh')
      should contain_file('/usr/lib/jiocloud/tests/nova-consoleauth.sh')
      should contain_file('/usr/lib/jiocloud/tests/nova-vncproxy.sh')
      should contain_class('rjil::test::nova_controller')
      should contain_runtime_fail('fail_before_nova').that_comes_before('Nova_config[DEFAULT/memcached_servers]')
      should contain_rjil__service_blocker('memcached').that_comes_before('Runtime_fail[fail_before_nova]')
      should contain_package('python-memcache').that_comes_before('Class[nova]')
      should contain_Nova_config('database/connection').that_requires('Rjil::Service_blocker[master.mysql]')
      should contain_nova_config('DEFAULT/rpc_zmq_bind_address').with_value('*')
      should contain_nova_config('DEFAULT/ring_file').with_value('/etc/oslo/matchmaker_ring.json')
      should contain_nova_config('DEFAULT/rpc_zmq_port').with_value(9501)
      should contain_nova_config('DEFAULT/rpc_zmq_contexts').with_value(1)
      should contain_nova_config('DEFAULT/rpc_zmq_ipc_dir').with_value('/var/run/openstack')
      should contain_nova_config('DEFAULT/rpc_zmq_matchmaker').with_value('oslo.messaging._drivers.matchmaker_ring.MatchMakerRing')
      should contain_nova_config('DEFAULT/rpc_zmq_host').with_value('node1')
      should contain_package('python-six')
      should contain_class('nova').with({
        'memcached_servers' => ['10.2.2.1:11211','10.2.2.2:11211']
      })
      should contain_class('nova::client')
      should contain_class('nova::api')
      should contain_class('nova::scheduler')
      should contain_class('nova::network::neutron')
      should contain_class('nova::conductor')
      should contain_class('nova::cert')
      should contain_class('nova::consoleauth')
      should contain_class('nova::vncproxy')
      should contain_class('nova::quota')
      should contain_file('/var/log/nova/nova-manage.log').that_comes_before('Nova_config[database/connection]')
      should contain_rjil__jiocloud__consul__service('nova').with({
        'tags'          => ['real'],
        'port'          => 100,
        'check_command' => "/usr/lib/jiocloud/tests/service_checks/nova.sh"
      })
      should contain_rjil__jiocloud__consul__service('nova-scheduler').with({
        'port'          => 0,
        'check_command' => '/usr/lib/jiocloud/tests/service_checks/nova-scheduler.sh'
      })
      should contain_rjil__jiocloud__consul__service('nova-conductor').with({
        'port'          => 0,
        'check_command' => '/usr/lib/jiocloud/tests/service_checks/nova-conductor.sh'
      })
      should contain_rjil__jiocloud__consul__service('nova-cert').with({
        'port'          => 0,
        'check_command' => '/usr/lib/jiocloud/tests/service_checks/nova-cert.sh'
      })
      should contain_rjil__jiocloud__consul__service('nova-consoleauth').with({
        'port'          => 0,
        'check_command' => '/usr/lib/jiocloud/tests/service_checks/nova-consoleauth.sh'
      })
      should contain_rjil__jiocloud__consul__service('nova-vncproxy').with({
        'port'          => 101,
        'tags'          => ['real'],
        'check_command' => "/usr/lib/nagios/plugins/check_http -H localhost -p 101 -u /vnc_auto.html",
      })
      ['nova-api', 'nova-manage', 'nova-cert', 'nova-conductor', 'nova-consoleauth', 'nova-novncproxy', 'nova-scheduler'].each do |x|
        should contain_rjil__jiocloud__logrotate(x).with_logdir('/var/log/nova/')
      end
    end
  end
end
