require 'resolv'

Puppet::Type.type(:ceph_monconfig_autodiscover).provide(
  :dns,
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do
  desc "Provider for dns based service discovery"

  def self.file_path
    '/etc/ceph/ceph.conf'
  end 


  def resolve
    Resolv::DNS.open do |dns|
      ress = dns.getresources(resource[:dnsname], Resolv::DNS::Resource::IN::SRV)
      names = ress.empty? ? []: ress.map { |r| r.target }.join(',').split(',')
      names.inject({}) do |srv,name|
        srv.update( name => dns.getresources(name,Resolv::DNS::Resource::IN::A).map{|a| a.address}.join)
      end
    end
  end


  def exists?
    nodes = resolve
    if resource[:monaddr]
      nodes[Facter['hostname'].value + '.local'] = resource[:monaddr]
    end
    if nodes.empty?
      fail("The Service name #{resource[:dnsname]} doesnt have any SRV records")
    end
    rv_final = true
    nodes.each do |name,ip|
      hostname = name.match(/^(\w+)\..*/)[1]
      rv1 = ini_file.get_value('mon.' + hostname,'host').eql? hostname
      rv2 = ini_file.get_value('mon.' + hostname,'mon addr').eql? ip + ':' + resource[:monport]
      if !rv1 || !rv2 
        rv_final = false
      end
    end
    return rv_final
  end

  def create
    nodes = resolve
    if resource[:monaddr]
      nodes[Facter['hostname'].value + '.local'] = resource[:monaddr]
    end
    if nodes.empty?
      fail("The Service name #{resource[:dnsname]} doesnt have any SRV records")
    end
    nodes.each do |name,ip|
      hostname = name.match(/^(\w+)\..*/)[1]
      ini_file.set_value('mon.' + hostname,'host',hostname)
      ini_file.set_value('mon.' + hostname,'mon addr',ip + ':' + resource[:monport])
      ini_file.save
      @ini_file =  nil
    end
  end

  def destroy
    nodes = resolve                                                      
    if resource[:monaddr]
      nodes[Facter['hostname'].value + '.local'] = resource[:monaddr]
    end
    if nodes.empty?                                                      
      fail("The Service name #{resource[:dnsname]} doesnt have any SRV records")
    end
    nodes.each do |name,ip|                                  
      hostname = name.match(/^(\w+)\..*/)[1]
      ini_file.remove_setting('mon.' + hostname,'host')
      ini_file.remove_setting('mon.' + hostname,'mon addr')
      ini_file.save
      @ini_file = nil
    end
  end
end
