require 'spec_helper'

describe 'rjil::haproxy::contrail' do
  let (:facts) { {
    :operatingsystem => 'Ubuntu',
    :osfamily        => 'Debian',
    :lsbdistid       => 'ubuntu',
    :ipaddress       => '10.1.1.1',
    :concat_basedir  => '/tmp'
  } }

  context 'with defaults' do
    it do
      should contain_rjil__haproxy_service('neutron').with({
        'vip'            => '0.0.0.0',
        'listen_ports'   => 9696,
        'balancer_ports' => 9697,
        'cluster_addresses' => '10.1.1.1'
      })
      should contain_rjil__haproxy_service('api').with({
        'vip'            => '0.0.0.0',
        'listen_ports'   => 8082,
        'balancer_ports' => 9100,
        'cluster_addresses' => '10.1.1.1'
      })
      should contain_rjil__haproxy_service('discovery').with({
        'vip'            => '0.0.0.0',
        'listen_ports'   => 5998,
        'balancer_ports' => 9110,
        'cluster_addresses' => '10.1.1.1'
      })
    end
  end

  context 'with multiple contrail servers and listen to one interface' do
    let (:params) { {
      :neutron_backend_ips            => ['10.1.1.1','10.1.1.2','10.1.1.3'],
      :neutron_listen_ports           => 9000,
      :neutron_balancer_ports           => 8000,
      :api_backend_ips       => ['10.1.1.1','10.1.1.2','10.1.1.3'],
      :discovery_backend_ips => ['10.1.1.1','10.1.1.2','10.1.1.3'],
      :vip                            => '10.1.1.100',
    } }
    it do
      should contain_rjil__haproxy_service('neutron').with({
        'vip'            => '10.1.1.100',
        'listen_ports'   => 9000,
        'balancer_ports' => 8000,
        'cluster_addresses' => ['10.1.1.1','10.1.1.2','10.1.1.3'],
      })
      should contain_rjil__haproxy_service('api').with({
        'vip'            => '10.1.1.100',
        'listen_ports'   => 8082,
        'balancer_ports' => 9100,
        'cluster_addresses' => ['10.1.1.1','10.1.1.2','10.1.1.3'],
      })
      should contain_rjil__haproxy_service('discovery').with({
        'vip'            => '10.1.1.100',
        'listen_ports'   => 5998,
        'balancer_ports' => 9110,
        'cluster_addresses' => ['10.1.1.1','10.1.1.2','10.1.1.3'],
      })
    end
  end
end
