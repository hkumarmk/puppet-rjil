#
# Setup docker
#
class rjil::docker (
  $containers        = {},
  $registry_url      = undef,
#  $insecure_registry = false,
) {

  ##
  # Install and setup docker on hosts
  ##
  include ::docker

  #create_resources('::docker::image',$images,{image_tag => $version})
  create_resources('rjil::docker::container', $containers, {registry => $registry_url})

}
