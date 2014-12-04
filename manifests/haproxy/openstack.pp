#
# Class: rjil::haproxy::openstack
#   Setup openstack services in haproxy.
#
class rjil::haproxy::openstack(
  $horizon_ips           = values(service_discover_consul('horizon', 'real')),
  $keystone_ips          = values(service_discover_consul('keystone', 'real')),
  $keystone_internal_ips = values(service_discover_consul('keystone-admin', 'real')),
  $glance_ips            = values(service_discover_consul('glance', 'real')),
  $cinder_ips            = values(service_discover_consul('cinder', 'real')),
  $nova_ips              = values(service_discover_consul('nova', 'real')),
  $neutron_ips           = values(service_discover_consul('neutron', 'real')),
  $radosgw_ips           = values(service_discover_consul('radosgw', 'real')),
  $radosgw_port          = '80',
  $horizon_port          = '80',
  $horizon_https_port    = '443',
  $novncproxy_port       = '6080',
  $keystone_public_port  = '5000',
  $keystone_admin_port   = '35357',
  $glance_port           = '9292',
  $glance_registry_port  = '9191',
  $cinder_port           = '8776',
  $nova_port             = '8774',
  $neutron_port          = '9696',
  $metadata_port         = '8775',
  $nova_ec2_port         = '8773',
) {

  ##
  # It is important to add all services details to validation checks.
  # Validation checks prevents any deployment issues (and thus leaving the
  # services unconfigured) and further errors by running puppet when it happens.
  ##

  ##
  # Port checks - this is very basic check which probe all ports mentioned.
  ##
  class { 'rjil::test::haproxy_openstack':
    ports  => [ $radosgw_port, $novncproxy_port, $keystone_public_port,
                $keystone_admin_port, $glance_port, $glance_registry_port,
                $cinder_port, $nova_port, $neutron_port, $metadata_port,
                $nova_ec2_port ],
  }

  ##
  # Backend checks - this will in fact go ahead and check if the particular
  # backend is registered and is up in haproxy or not.
  ##
  class { 'rjil::test::haproxy_backend_openstack':
    backend_services => {
                          'radosgw'         => $radosgw_ips,
                          'keystone'        => $keystone_ips,
                          'keystone-admin'  => $keystone_internal_ips,
                          'glance'          => $glance_ips,
                          'cinder'          => $cinder_ips,
                          'nova'            => $nova_ips,
                          'neutron'         => $neutron_ips,
                          'novncproxy'      => $nova_ips,
                          'glance-registry' => $glance_ips,
                          'metadata'        => $nova_ips,
                          'nova-ec2'        => $nova_ips,
                        }
  }

  rjil::haproxy_service { 'horizon':
    balancer_ports    => $horizon_port,
    cluster_addresses => $horizon_ips,
    listen_options   =>  {
      'balance'      => 'source',
      'option'       => ['tcpka','abortonclose']
    },
  }

  rjil::haproxy_service { 'radosgw':
    balancer_ports    => $radosgw_port,
    cluster_addresses => $radosgw_ips,
  }

  rjil::haproxy_service { 'horizon-https':
    balancer_ports    => $horizon_https_port,
    cluster_addresses => $horizon_ips,
  }

  rjil::haproxy_service { 'novncproxy':
    balancer_ports    => $novncproxy_port,
    cluster_addresses => $nova_ips,
  }

  rjil::haproxy_service { 'keystone':
    balancer_ports    => $keystone_public_port,
    cluster_addresses => $keystone_ips,
  }

  rjil::haproxy_service { 'keystone-admin':
    balancer_ports    => $keystone_admin_port,
    cluster_addresses => $keystone_internal_ips,
  }

  rjil::haproxy_service { 'glance':
    balancer_ports    => $glance_port,
    cluster_addresses => $glance_ips,
  }

  rjil::haproxy_service { 'neutron':
    balancer_ports    => $neutron_port,
    cluster_addresses => $neutron_ips,
  }

  rjil::haproxy_service { 'glance-registry':
    balancer_ports    => $glance_registry_port,
    cluster_addresses => $glance_ips,
  }

  rjil::haproxy_service { 'cinder':
    balancer_ports    => $cinder_port,
    cluster_addresses => $cinder_ips,
  }

  rjil::haproxy_service { 'nova':
    balancer_ports    => $nova_port,
    cluster_addresses => $nova_ips,
  }

  rjil::haproxy_service { 'metadata':
    balancer_ports    => $metadata_port,
    cluster_addresses => $nova_ips,
  }

  rjil::haproxy_service { 'nova-ec2':
    balancer_ports    => $nova_ec2_port,
    cluster_addresses => $nova_ips,
  }

}
