##
# facter to do leader election for mysql master-slave cluster
##
if Facter.value(:jiocloud_role) == 'ocdb'
  require 'jiocloud/utils'
  include Jiocloud::Utils
  key = 'services/openstack/mysql/leader'
  hostname = Facter.value(:hostname)
  casSession(hostname)

  ##
  # get session lock
  ##

  leader = true if createKV(key,hostname,{'acquire' => hostname}) == true || (leader_name = getKV(key)) == hostname

  Facter.add(:openstack_mysql_leader) do
    setcode do
      if leader
        hostname
      else
        leader_name
      end
    end
  end

  Facter.add(:orc_node_status) do
    setcode do
      if leader
        'leader'
      else
        'follower'
      end
    end
  end
end
