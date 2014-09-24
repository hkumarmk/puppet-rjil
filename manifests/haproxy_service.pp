#
# Define: rjil::haproxy_service
#

define rjil::haproxy_service(
  $vip               = '0.0.0.0',
  $balancer_ports    = [],
  $listen_ports      = [],
  $cluster_addresses = [],
  $listen_options    =  {
    'option'  => 'tcpka',
    'option'  => 'abortonclose',
    'balance' => 'roundrobin',
  },
  $listen_mode      = 'tcp',
  $balancer_options = 'check inter 10s rise 2 fall 3',
  $balancer_cookie  = undef,
  $bind_options     = undef,
) {

  if $cluster_addresses != [] {
    ## Listen ports can be different from balancer ports
    ## This is applicable for contrail servers
    ## So enabling a way to provide both the ports if required

    if $listen_ports == [] {
      if $balancer_ports  != [] {
        $listen_ports_orig = $balancer_ports
      } else {
        fail('Either balancer_ports or listen_ports must be provided')
      }
    } else {
      $listen_ports_orig = $listen_ports
    }

    if $balancer_ports == [] {
      if $listen_ports  != [] {
        $balancer_ports_orig = $listen_ports
      } else {
        fail('Either balancer_ports or listen_ports must be provided')
      }
    } else {
      $balancer_ports_orig = $balancer_ports
    }

    ::haproxy::listen { $name:
      ipaddress        => $vip,
      ports            => $listen_ports_orig,
      mode             => $listen_mode,
      collect_exported => false,
      options          => $listen_options,
      bind_options     => $bind_options
    }

    ::haproxy::balancermember { $name:
      listening_service => $name,
      ports             => $balancer_ports_orig,
      server_names      => $cluster_addresses,
      ipaddresses       => $cluster_addresses,
      options           => $balancer_options,
      define_cookies    => $balancer_cookie
    }
  }
}
