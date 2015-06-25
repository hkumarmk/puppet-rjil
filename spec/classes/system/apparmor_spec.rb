require 'spec_helper'

describe 'rjil::system::apparmor' do
  let(:facts) { {:operatingsystem => 'Debian', :osfamily => 'Debian'}}

  it 'should install and start apparmor' do
    should contain_package('apparmor').with_ensure('present')
    should contain_service('apparmor').with_ensure('running')
  end
end
