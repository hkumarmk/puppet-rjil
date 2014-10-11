require 'resolv'
Puppet::Type.newtype(:ceph_monconfig_autodiscover) do
  @doc = <<-EOS
This type is to do autodiscovery and generate ceph mon configuration entries.

Parameters:
  1. dns_name 
      Here assuming dns_name is a dns srv record which resolve all servers with
      which runs ceph mon service. The advantage here is that one can use
      DNS based service discovery tools like consul to discovery ceph mon services.
  2. monport
      The port ceph mon should listen to. Default:6789

Note: Manual ceph mon configuration is not handled here, it can be handled using
generic ceph_config which can directly use provider ini_setting.

Example: 
  ceph_monconfig_autodiscover {'abc':
    dns_name => stmon.service.consul,
  }

  Assuming stmon.service.consul will resolve srv records as below
    stmon1.node.consul - 10.1.0.1
    stmon2.node.consul - 10.1.0.2

  This example write below config entries will be added to /etc/ceph/ceph.conf
  [mon.stmon1]
  host=stmon1
  mon addr=10.1.0.1:6789

  [mon.stmon2]
  host=stmon2
  mon addr=10.1.0.2:6789
EOS

  ensurable

  newparam(:name, :namevar => true) do
    newvalues(/\S+/)
  end

  newparam(:dnsname) do
    desc 'Service name in dns which have SRV records for all ceph mon nodes.'
    newvalues(/\S+\.\S+/)
  end

  newparam(:leader, :boolean => true) do
    desc 'Whether this node is leader or not. This will be used during cluster
initilazation stage when there is no record in dnsname'

    newvalues(:true, :false)
    defaultto false
  end

  newparam(:monport) do
    desc "Mon port"
    newvalues(/\d+/)
    defaultto '6789'
  end

  newparam(:monaddr) do
    desc "Mon address. This will be used during cluster initialization stage,
when there is no SRV record in dnsname on leader.
    This parameter has effect only on leader node."

    newvalues(/\d+\.\d+\.\d+\.\d+/)
    
    validate do |value|
      value =~ Resolv::IPv4::Regex ? true : fail("#{value}: Not Valid IPAddress")
    end
  end
end
