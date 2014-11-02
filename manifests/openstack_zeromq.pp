#
#Class rjil::openstack_zeromq
#
# == Parameters
# [*cinder_scheduler_nodes*]
#   A hash of hostname and ip pairs
#
# [*cinder_volume_nodes*]
#   A hash of hostname and ip pairs
#
# [*nova_scheduler_nodes*]
#   A hash of hostname and ip pairs
#
# [*nova_consoleauth_nodes*]
#   A hash of hostname and ip pairs
#
# [*nova_conductor_nodes*]
#   A hash of hostname and ip pairs
#
# [*nova_cert_nodes*]
#   A hash of hostname and ip pairs
#
# [*nova_compute_nodes*]
#   A hash of hostname and ip pairs of compute nodes
# == Action
#   1. Resolve srv records for the names given,
#   2. Add /etc/hosts entry for the hostname part of fqdn, so that the hostnames can be resolved.
#   3. Call ::openstack_zeromq with an array of hostnames striped from fqdn.
#
# == NOTE
# Because of the cross dependency between cinder-volume and cinder-scheduler,
#   it take two puppet runs to configure matchmaker entry for cinder-scheduler.
#   cinder-scheduler will not start in the first puppet run because of the lack
#   of cinder-volume matchmaker entry. Since we use puppet function for service
#   discovery, only second puppet run get the service IPs.


class rjil::openstack_zeromq (
  $cinder_scheduler_nodes = service_discover_consul('cinder-scheduler'),
  $cinder_volume_nodes    = service_discover_consul('cinder-volume'),
  $nova_scheduler_nodes   = service_discover_consul('nova-scheduler'),
  $nova_consoleauth_nodes = service_discover_consul('nova-consoleauth'),
  $nova_conductor_nodes   = service_discover_consul('nova-conductor'),
  $nova_cert_nodes        = service_discover_consul('nova-cert'),
  $nova_compute_nodes     = service_discover_consul('nova-compute'),
) {

  ##
  # Add hosts entries. This is required because zmq receiver need matchmaker
  # entries which matching hosts hostname (result of hostname -s). So matchmaker
  # will have only hostname part of the fqdn which must be resolved to connect
  # to the system by zmq driver.
  ##

  $merged_hosts = merge($cinder_volume_nodes,
                        $cinder_scheduler_nodes,
                        $nova_scheduler_nodes,
                        $nova_consoleauth_nodes,
                        $nova_conductor_nodes,
                        $nova_cert_nodes
                        )

  easy_host($merged_hosts)

  ##
  # Extract hostname part from fqdn, which will be used to generate matchmaker
  # ring file.
  ##

  $cinder_scheduler_nodes_orig = regsubst(keys($cinder_scheduler_nodes),'^([\w-]+)\.\S+','\1')
  $cinder_volume_nodes_orig    = regsubst(keys($cinder_volume_nodes),'^([\w-]+)\.\S+','\1')
  $nova_scheduler_nodes_orig   = regsubst(keys($nova_scheduler_nodes),'^([\w-]+)\.\S+','\1')
  $nova_consoleauth_nodes_orig = regsubst(keys($nova_consoleauth_nodes),'^([\w-]+)\.\S+','\1')
  $nova_conductor_nodes_orig   = regsubst(keys($nova_conductor_nodes),'^([\w-]+)\.\S+','\1')
  $nova_cert_nodes_orig        = regsubst(keys($nova_cert_nodes),'^([\w-]+)\.\S+','\1')
  $nova_compute_nodes_orig     = regsubst(keys($nova_compute_nodes),'^([\w-]+)\.\S+','\1')

  class { '::openstack_zeromq':
    cinder_scheduler_nodes => $cinder_scheduler_nodes_orig,
    cinder_volume_nodes    => $cinder_volume_nodes_orig,
    nova_scheduler_nodes   => $nova_scheduler_nodes_orig,
    nova_consoleauth_nodes => $nova_consoleauth_nodes_orig,
    nova_conductor_nodes   => $nova_conductor_nodes_orig,
    nova_cert_nodes        => $nova_cert_nodes_orig,
    nova_compute_nodes     => $nova_compute_nodes_orig,
  }
}
