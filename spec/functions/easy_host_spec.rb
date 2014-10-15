require 'spec_helper'
require 'rspec-puppet'
describe 'easy_host' do

  context 'with more than one argument' do
    it 'should only accept one argument' do
      expect do
        should run.with_params('FOO').and_return('bar')
      end.to raise_error(ArgumentError, /Argument must be a hash/)
    end
  end
end
