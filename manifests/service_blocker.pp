#
# This resource blocks until an expected service is registered
# with consul. It assumes that the environment used as the
# datacenter for consul default to $::env.
#
# It assumes that the address for each service is
#
#   ${name}.service.${datacenter}.consul
#
# It also assumes that addresses will not resolve if the
# backend service does not work (do it defers ensuring
# the service is resolvable to consul)
#
define rjil::service_blocker(
  $timeout    = 600,
  $try_sleep  = 20,
  $datacenter = $::env,
) {

  $service_hostname = "${name}.service.${datacenter}.consul"

  # block until an expected address is registered with
  # DNS. This assumes that the services is registered
  # with DNS via consul, so we can trust that the
  # ability to resolve a host, means the service is
  # reachable
  $cmd = "dig ${service_hostname} | grep -A1 ';; ANSWER SECTION:' | grep ${service_hostname}"
  exec { "block_until_${name}_is_ready":
    command   => $cmd,
    unless    => $cmd,
    path      => ['/usr/bin/', '/bin'],
    timeout   => $timeout,
    try_sleep => $try_sleep,
    tries     => $timeout/$try_sleep,
    logoutput => true,
  }

  Exec <| title == 'reload-consul' |> -> Rjil::Service_blocker[$name]

}
