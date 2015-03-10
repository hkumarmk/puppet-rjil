##
# This fact is only required to be run on HP storage nodes.
#
##
Facter.add(:hp_unassigned_disks) do
  setcode do
    if Facter.value(:jiocloud_role) =~ /(st|stmon)/ && Facter.value(:manufacturer) =~ /^HP$/
      Facter::Util::Resolution.exec("hpacucli ctrl slot=1 pd all show  | sed -e '1,/unassigned/d' -e '/^ *\$/d' | awk '{print \$2}'").split.join(',')
    end
  end
end
