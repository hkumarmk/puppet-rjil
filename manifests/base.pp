#
# Class rjil::base
#
class rjil::base (
  $self_signed_cert = false,
) {
  include rjil::jiocloud
  include rjil::system
  include rjil::jiocloud::dns
  include rjil::default_manifest
  include rjil::system::sensitive_services
  include rjil::rsyslog
  ##
  # In case of self signed certificate mostly all of the servers need to trust
  # tht certificate as it is required to do api calls to any openstack services
  # in case of ssl enabled.
  ##
  if $self_signed_cert {
    include rjil::trust_selfsigned_cert
  }
}

