require'spec_helper'
describe 'service_discover_dns' do
  it 'should accept two arguments' do
    expect do
      should run.with_params().and_return('bar')
    end.to raise_error(ArgumentError, /name must be specified/)
  end
  it  do
    should run.with_params('node1.example.com','name')
    should run.with_params('node1.example.com','ip')
    should run.with_params('node1.example.com','both')
    expect do
      should run.with_params('node1.example.com','invalid_param').and_return('test')
    end.to raise_error(ArgumentError, /invalid_param is not a valid result type./)
  end
end
