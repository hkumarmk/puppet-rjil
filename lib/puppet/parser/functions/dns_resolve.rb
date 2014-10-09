##
## dns_resolve
##
module Puppet::Parser::Functions
  newfunction(
    :dns_resolve, 
    :type  => :rvalue, 
    :arity => 1,
    :doc   => <<-EOS

This function does dns forward lookup and returns a comma separated list of IP
addresses
Accepts one parameter which is the name to be resolved.

Example: 
  dns_resolve("google.com")

The above example will return a comma separated list of IP addresses which
resolve google.com.
EOS
  ) do |args|
    Resolv::DNS.open do |dns|
      ress = dns.getresources(args[0], Resolv::DNS::Resource::IN::A)
      ress.empty? ? '': ress.map { |r| r.address }.join(',')
    end
  end
end

# vim:sts=2 sw=2
