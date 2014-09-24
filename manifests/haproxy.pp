#
# This has been shamelessly lifed from stacktira
#
# This is essentially the profile for haproxy
#
#
class rjil::haproxy () {

  rjil::test { 'haproxy.sh': }

  $haproxy_defaults = {
    'log'        => 'global',
    'mode'       => 'http',
    'option'     => ['httplog', 'dontlognull', 'redispatch'],
    'retries'    => '3',
    'maxconn'    => '2000',
    'timeout'    => ['connect 5000', 'client 10000', 'server 10000'],
    'errorfile' => [
                      '400 /etc/haproxy/errors/400.http',
                      '403 /etc/haproxy/errors/403.http',
                      '408 /etc/haproxy/errors/408.http',
                      '500 /etc/haproxy/errors/500.http',
                      '502 /etc/haproxy/errors/502.http',
                      '503 /etc/haproxy/errors/503.http',
                      '504 /etc/haproxy/errors/504.http'
                    ],
  }

  $haproxy_globals = {
    'log'       => '127.0.0.1 local0 notice',
    'maxconn'   => '4096',
    'user'      => 'haproxy',
    'group'     => 'haproxy',
    'daemon'    => '',
    'quiet'     => '',
    'stats'     => 'socket /var/run/haproxy mode 777',
  }

  class { '::haproxy':
    global_options   => $haproxy_globals,
    defaults_options => $haproxy_defaults
  }

#
# commented out configuration related to keepalive d
# for multiple lbs
#

  haproxy::listen { 'lb-stats':
    ipaddress => '0.0.0.0',
    ports     => '8094',
    mode      => 'http',
    options   => {
      'option'  => [
        'httplog',
      ],
      'stats' => ['enable', 'uri /lb-stats'],
    },
  }

#  if $cluster_master == $::fqdn {
#    $state = 'MASTER'
#  } else {
#    $state = 'BACKUP'
#  }

#  # configure vips
#  include keepalived

#  sysctl { 'net.ipv4.ip_nonlocal_bind':
#    value  => '1',
#    before => Class['::keepalived']
#  }

  # Since vswitch now moves ip addresses of interfaces to
  # their attached ovs bridge, that bridge needs to be the
  # public interface, and must be ready before keepalived starts
#  Vs_port<||> -> Class['::keepalived']
#  Vs_bridge<||> -> Class['::keepalived']

#  keepalived::vrrp::instance { 'public':
#    interface           => $public_iface,
#    state               => $state,
#    virtual_router_id   => $public_vrid,
#    priority            => '101',
#    auth_type           => 'PASS',
#    auth_pass           => $vip_secret,
#    virtual_ipaddress   => [$cluster_public_vip],
#  } -> Class['::haproxy']

#  keepalived::vrrp::instance { 'private':
#    interface           => $private_iface,
#    state               => $state,
#    virtual_router_id   => $private_vrid,
#    priority            => '101',
#    auth_type           => 'PASS',
#    auth_pass           => $vip_secret,
#    virtual_ipaddress   => [$cluster_private_vip],
#  } -> Class['::haproxy']

  # Openstack services depend on being able to access db and mq, so make
  # sure our VIPs and LB are active before we deal with them.
  Haproxy::Listen<||> -> Anchor <| title == 'mysql::server::start' |>
  Haproxy::Listen<||> -> Anchor <| title == 'rabbitmq::begin' |>
  Haproxy::Balancermember<||> -> Anchor <| title == 'mysql::server::start' |>
  Haproxy::Balancermember<||> -> Anchor <| title == 'rabbitmq::begin' |>
  Service<| title == 'haproxy' |> -> Anchor <| title == 'rabbitmq::begin' |>
  Service<| title == 'haproxy' |> -> Anchor <| title == 'mysql::server::start' |>

#  if $package_override {
#    Package<| title == 'haproxy' |> {
#      provider => 'rpm',
#      source   => $package_override
#    }
#  }
}
