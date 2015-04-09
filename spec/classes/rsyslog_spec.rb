require 'spec_helper'

describe 'rjil::rsyslog' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :lsbdistid       => 'ubuntu',
    }
  end

  context 'with defaults' do
    it do
      should contain_rjil__test__check('rsyslogd').with(
        {
          :type     => 'proc',
          :consumer => 'validation',
        }
      )
      should contain_file('/usr/lib/jiocloud/tests/rsyslogd.sh')
      should contain_class('rsyslog::server')
    end
  end

end
