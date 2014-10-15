##
## service_discover_dns
##
module Puppet::Parser::Functions
  newfunction(
    :service_discover_dns,
    :type  => :rvalue,
    :doc   => <<-EOS

This function does DNS SRV lookup and returns the data.

This function accepts below parameters:

1. name to be resolved
2. What to return. There are three valid parameters: name, ip or both
  * name: return array of names get from SRV lookup
  * ip  : return array of IP addresses
  * both: return a hash of both name and ip addresses

Example:
  service_discover_dns("web.example.com",ip)

The above example will return an array of all server IPs in web.example.com SRV
dns record.

EOS
  ) do |args|
    name,output =  args

    output =  'name' unless output
    raise(ArgumentError, "name must be specified") unless name
    Resolv::DNS.open do |dns|
      ress = dns.getresources(name, Resolv::DNS::Resource::IN::SRV)
      names = ress.empty? ? []: ress.map { |r| r.target }.join(',').split(',')
      if output == 'name'
        return names
      elsif output == 'ip'
        ips = names.map {|name| dns.getresources(name,Resolv::DNS::Resource::IN::A).map{|a| a.address}.join}
        return ips
      elsif output == 'both'
        names.inject({}) do |srv,name|
          srv.update( name => dns.getresources(name,Resolv::DNS::Resource::IN::A).map{|a| a.address}.join)
        end
      else
        raise(ArgumentError, "#{output} is not a valid result type.")
      end
    end
  end
end

# vim:sts=2 sw=2
