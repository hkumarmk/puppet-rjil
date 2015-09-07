if Facter.value(:kernel) == 'Linux'
  disk_by_path_directory = '/dev/disk/by-path/'
  nonsystem_disks = []
  Dir.entries(disk_by_path_directory).reject{|d| d =~ /-part/}.each do |disk|
    next unless File.blockdev?(disk_by_path_directory + disk)
    nonsystem_disks << File.basename(File.realpath(disk_by_path_directory + disk))
  end

  system_disks = Facter.value(:blockdevices).split(/,/) - nonsystem_disks
  unless nonsystem_disks.empty?
    Facter.add(:nonsystem_disks) do
      setcode { nonsystem_disks.sort.join(',') }
    end
  end

  unless system_disks.empty?
    Facter.add(:system_disks) do
      setcode { system_disks.sort.join(',') }
    end
  end
end
