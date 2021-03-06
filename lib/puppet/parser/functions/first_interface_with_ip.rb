##
## first_interface_with_ip
##
require 'ipaddr'

module Puppet::Parser::Functions
  newfunction(
    :first_interface_with_ip,
    :type => :rvalue,
    :doc => <<-EOS

This function does below stuffs.

* Iterate through the 'interfaces' fact and return the first interface details
 which have any ip address set.
* It can also accepts a comma separated interface names
* The details it can provide is interface name, ip address, network, subnetmask.

It takes two optional arguments

1. what to return. Valid arguments are
    interface: return interface name
    ipaddress: return ipaddress
    macaddress: return macaddress
    network:  return network
    netmask:  return netmask
   By default it return interface name.

2. Interface list - a comma separated interface list to check.
    If not provided, it use 'interfaces' fact.

  e.g
    Below example return ipaddress of first interface from the list provided which
  has any ip address set.

  first_interface_with_ip('ipaddress','eth0,eth1,vhost0')

    EOS
    ) do |args|

    kind_arg       = args.shift
    interface_list = args.shift
    ifs = defined?(interface_list) ? interface_list : lookupvar('interfaces')
    raise(ArgumentError, "interfaces cannot be empty") if !ifs || ifs.empty?


    kind = defined?(kind_arg) ? kind_arg : 'interface'

    ifs.split(',').each do |iface|
      if lookupvar("ipaddress_#{iface}")
        if kind == 'interface'
          return iface
        else
          return lookupvar("#{kind}_#{iface}")
        end
      end
    end
  end
end

# vim:sts=2 sw=2
