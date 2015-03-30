#
# Class rjil::golden_image
#
class rjil::golden_image (
  $self_signed_cert = false,
  $packages         =
['python-jiocloud','dnsmasq','consul','run-one','molly-guard','libguestfs-tools']
) {
  include rjil::system

  # Python-six must be latest one
  ensure_resource('package','python-six', { ensure => 'latest' })


  Package['python-jiocloud'] -> Package['dnsmasq']
  Package['python-jiocloud'] -> Package['consul']

  include rjil::default_manifest

  ensure_packages($packages)
  ##
  # In case of self signed certificate mostly all of the servers need to trust
  # tht certificate as it is required to do api calls to any openstack services
  # in case of ssl enabled.
  ##
  if $self_signed_cert {
    include rjil::trust_selfsigned_cert
  }
}
