require'spec_helper'
describe 'dns_resolve' do
  it 'should only accept one argument' do
    expect do
      should run.with_params('FOO','bar').and_return('bar')
    end.to raise_error(ArgumentError, /Wrong number of arguments given/)
  end
  it 'should return valid IP for a given name' do
    should run.with_params("google.com")
  end
end  
