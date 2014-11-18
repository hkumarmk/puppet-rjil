require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::memcached' do

  let(:facts) do
    {
      :osfamily       => 'Debian',
      :memorysize     => '1000',
    }
  end

  context 'with defaults' do
    it do
      should contain_file('/usr/lib/jiocloud/tests/memcached.sh')
      should contain_class('memcached')
      should contain_rjil__jiocloud__consul__service('memcached').with({
        'port'          => 11211,
        'check_command' => 'echo stats | nc localhost 11211 | grep -q uptime'
      })
    end
  end
end
