## Class rjil::ceph::mon
## Purpose: Configure ceph mon
class rjil::ceph::mon (
  $public_if,
  $key,
  $pools          = ['volumes','backups','images'],
  $pool_pg_num    = 128,
) {

  ## Class rjil::ceph::mon should be executed after Class rjil::ceph
  Class['rjil::ceph'] -> Class['rjil::ceph::mon']

  ## Derive mon_addr - this is the IP address of public interface on mon node
  $mon_addr = inline_template("<%= scope.lookupvar('ipaddress_' + @public_if) %>")

  ## Setup ceph mons
  ::ceph::mon { $hostname:
    monitor_secret => $key,
    mon_addr       => $mon_addr,
  }


  ## Add osd pools
  ::ceph::osd::pool{ $pools:
    num_pgs => $pool_pg_num,
    require => Ceph::Mon[$hostname],
  }
}
