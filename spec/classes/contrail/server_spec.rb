require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::contrail::server' do
  let :facts do
    {
      :operatingsystem => 'Debian',
      :osfamily        => 'Debian',
      :ipaddress_eth0  => '10.1.1.1',
      :interfaces      => 'eth0,lo',
      :lsbdistid        => 'ubuntu',
      :lsbdistcodename  => 'trusty',
    }
  end
  let :hiera_data do
    {
      'contrail::keystone_address'        => 'keystone_public_address',
      'contrail::keystone_admin_token'    => 'admin_token',
      'contrail::keystone_admin_password' => 'admin_pass',
      'contrail::keystone_auth_password'  => 'auth_pass',
    }
  end

  context 'with defaults' do
    it do
      should contain_file('/usr/lib/jiocloud/tests/ifmap.sh')
      should contain_file('/usr/lib/jiocloud/tests/contrail-analytics.sh')
      should contain_file('/usr/lib/jiocloud/tests/contrail-api.sh')
      should contain_file('/usr/lib/jiocloud/tests/contrail-control.sh')
      should contain_file('/usr/lib/jiocloud/tests/contrail-discovery.sh')
      should contain_file('/usr/lib/jiocloud/tests/contrail-dns.sh')
      should contain_file('/usr/lib/jiocloud/tests/contrail-schema.sh')
      should contain_file('/usr/lib/jiocloud/tests/contrail-webui-webserver.sh')
      should contain_file('/usr/lib/jiocloud/tests/contrail-webui-jobserver.sh')
      should contain_class('contrail')
      ['contrail-api-daily','contrail-discovery-daily','contrail-schema-daily','contrail-svc-monitor-daily','contrail-control','contrail-ifmap-server','contrail-dns','contrail-collector-daily']. each do |x|
        should contain_rjil__jiocloud__logrotate(x).with_logdir('/var/log/contrail')
      end
      ['contrail-config','contrail-config-openstack','ifmap-server','contrail-analytics']. each do |x|
        should contain_rjil__jiocloud__logrotate(x).with_ensure('absent')
      end
    end
  end

  context 'without config, webui' do
    let :params do
      {
        :enable_config => false,
        :enable_webui  => false,
      }
    end

    it do
      should_not contain_file('/usr/lib/jiocloud/tests/contrail-api.sh')
      should_not contain_file('/usr/lib/jiocloud/tests/contrail-discovery.sh')
      should_not contain_file('/usr/lib/jiocloud/tests/contrail-schema.sh')
      should_not contain_file('/usr/lib/jiocloud/tests/contrail-webui-webserver.sh')
      should_not contain_file('/usr/lib/jiocloud/tests/contrail-webui-jobserver.sh')
      should contain_class('contrail').with_enable_config(false)
      should contain_class('contrail').with_enable_webui(false)
    end
  end

    context 'without control,analytics,ifmap' do
    let :params do
      {
        :enable_control   => false,
        :enable_analytics => false,
        :enable_ifmap     => false,
      }
    end

    it do
      should_not contain_file('/usr/lib/jiocloud/tests/contrail-control.sh')
      should_not contain_file('/usr/lib/jiocloud/tests/contrail-dns.sh')
      should_not contain_file('/usr/lib/jiocloud/tests/contrail-analytics.sh')
      should_not contain_file('/usr/lib/jiocloud/tests/ifmap.sh')
      should contain_class('contrail').with_enable_control(false)
      should contain_class('contrail').with_enable_analytics(false)
      should contain_class('contrail').with_enable_ifmap(false)
    end
  end
end
