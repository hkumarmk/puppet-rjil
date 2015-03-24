#
# Class rjil::http_proxy
# stands up a squid proxy for gcp node types
#
class rjil::http_proxy() {

  include squid3

  Service<| title == 'squid3_service' |> {
    provider => 'upstart',
    enable   => undef,
  }

  rjil::jiocloud::consul::service {'proxy':
    port          => '3128',
    tags          => ['real'],
    check_command => "/usr/lib/nagios/plugins/check_http -H localhost -p 3128",
  }

}

