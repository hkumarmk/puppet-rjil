require 'spec_helper'

describe 'rjil::haproxy' do

  let :facts do
    {
      :osfamily       => 'Debian',
      :concat_basedir => '/tmp'
    }
  end


  it 'should install haproxy' do

    should contain_rjil__test('haproxy.sh')
    should contain_rjil__jiocloud__consul__service('haproxy').with({
      'tags' => []
    })
    should contain_rsyslog__snippet('haproxy').with(
      {
        :content => 'local0.* -/var/log/haproxy.log',
      }
    )
  end

  context 'consul_service_tags are provided' do
    let :params do
      {
        'consul_service_tags' => ['foo', 'bar']
      }
    end
    it 'should set set the tags on consul service' do
      should contain_rjil__jiocloud__consul__service('haproxy').with({
        'tags' => ['foo', 'bar']
      })
    end
  end
end
