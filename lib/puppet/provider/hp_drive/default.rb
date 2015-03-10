Puppet::Type.type(:hp_drive).provide(
  :default,
) do

  commands :hpacucli => 'hpacucli'

  def exists?
    !!(hpacucli('ctrl slot=1 pd ',resource[:name],'show') !~ /unassigned/)
  end

  def create
    hpacucli('ctrl slot=1 create type=ld
',"drives=#{resource[:name]}","raid=#{resource[:raid_level]}")
  end

  ##
  # I dont know if we wanted to support delete Lun, it is bit complecated and
  # destroy can cause dataloss.
  ##
  def destroy
    warning("hp_drive does not support removing logical drive")
    true
  end

end
