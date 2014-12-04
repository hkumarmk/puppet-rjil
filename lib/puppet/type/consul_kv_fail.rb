Puppet::Type.newtype(:consul_kv_fail) do

  desc <<-'EOD'
  Fail the resource until find specific consul Key/value pair and thus all
dependant resources to consul_kv_fail will fail.
  This will help to avoid configuring any dependant resources without the
dependancy available. This does better job (than consul_kv_blocker) by just
failing only dependant resources and allowing other resources to be configured.
  EOD

  newparam(:name, :namevar => true) do
    desc 'Consul Key name'
  end

  newparam(:url) do
    desc 'Consul url to use'
    defaultto 'http://localhost:8500/v1/kv'
  end

  newproperty(:ready) do
    defaultto true
  end

  validate do
    raise(Puppet::Error, 'Ready should not be set') unless self[:ready] == true
  end

end
