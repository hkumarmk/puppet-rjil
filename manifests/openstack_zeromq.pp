#
#Class rjil::openstack_zeromq
#
# == Parameters
# [*cinder_scheduler_nodes*]
#   A hash of hostname and ip paires 
#
# [*cinder_volume_nodes*]
#   A hash of hostname and ip paires 
#
# [*nova_scheduler_nodes*]
#   A hash of hostname and ip paires 
#
# [*nova_consoleauth_nodes*]
#   A hash of hostname and ip paires 
#
# [*nova_conductor_nodes*]
#   A hash of hostname and ip paires 
#
# [*nova_cert_nodes*]
#   A hash of hostname and ip paires 
#
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
  $cinder_scheduler_nodes = service_discover_dns('cinder-scheduler.service.consul','both'),
  $cinder_volume_nodes    = service_discover_dns('cinder-volume.service.consul','both'),
  $nova_scheduler_nodes   = service_discover_dns('nova-scheduler.service.consul','both'),
  $nova_consoleauth_nodes = service_discover_dns('nova-consoleauth.service.consul','both'),
  $nova_conductor_nodes   = service_discover_dns('nova-conductor.service.consul','both'),
  $nova_cert_nodes        = service_discover_dns('nova-cert.service.consul','both'),
) {

  ##
  # matchmaker entry must be matching hostname (output of hostname -s)
  # So getting a hash of node fqdn and IP address from consul,
  # Add /etc/hosts entries with fqdn and hostname, so the name will be resolved.
  # (e.g if fqdn is node1.example.com, a host entry created as below.
  #   10.1.1.1 node1.example.com node1
  ##
  # Resolve the SRV record and get a hash of name (fqdn) and IP address)
  ##


  ##
  # Add hosts entries. This is required because zmq receiver need matchmaker
  # entries which matching hosts hostname (result of hostname -s). So matchmaker
  # will have only hostname part of the fqdn which must be resolved to connect
  # to the system by zmq driver.
  ##

  easy_host($cinder_volume_nodes)
  easy_host($cinder_scheduler_nodes)
  easy_host($nova_scheduler_nodes)
  easy_host($nova_consoleauth_nodes)
  easy_host($nova_conductor_nodes)
  easy_host($nova_cert_nodes)

  ##
  # Extract hostname part from fqdn, which will be used to generate matchmaker
  # ring file.
  ##

  $cinder_scheduler_nodes_orig = regsubst(keys($cinder_scheduler_nodes),'^([\w-]+)\.\S+','\1')
  $cinder_volume_nodes_orig = regsubst(keys($cinder_volume_nodes),'^([\w-]+)\.\S+','\1')
  $nova_scheduler_nodes_orig = regsubst(keys($nova_scheduler_nodes),'^([\w-]+)\.\S+','\1')
  $nova_consoleauth_nodes_orig = regsubst(keys($nova_consoleauth_nodes),'^([\w-]+)\.\S+','\1')
  $nova_conductor_nodes_orig = regsubst(keys($nova_conductor_nodes),'^([\w-]+)\.\S+','\1')
  $nova_cert_nodes_orig = regsubst(keys($nova_cert_nodes),'^([\w-]+)\.\S+','\1')

  class { '::openstack_zeromq':
    cinder_scheduler_nodes => $cinder_scheduler_nodes_orig,
    cinder_volume_nodes    => $cinder_volume_nodes_orig,
    nova_scheduler_nodes   => $nova_scheduler_nodes_orig,
    nova_consoleauth_nodes => $nova_consoleauth_nodes_orig,
    nova_conductor_nodes   => $nova_conductor_nodes_orig,
    nova_cert_nodes        => $nova_cert_nodes_orig,
  }
}
