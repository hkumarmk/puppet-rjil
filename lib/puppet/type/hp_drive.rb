Puppet::Type.newtype(:hp_drive) do
##
# TODO: thiscode will only support single drive raid0 as of now, This is to be
# fixed.
##

  desc <<-'EOD'
Manage hp drives and make RAID on top of the drives.
  EOD


  ensurable do
    defaultto(:present)
    newvalue(:present) do
      provider.create
    end
    newvalue(:absent) do
      provider.destroy
    end
  end
#  ensurable do
#    defaultto(:present)
#  end

  newparam(:name, :namevar => true) do
    desc 'drive name'
  end

  newparam(:raid_level) do
    desc 'Raid level, default to zero'
    defaultto 0
  end

end
