#
# Setup docker
#
# [*containers*]
#   A hash with containers to be spawned
#
# [*registry_url*]
#   Docker Registry url
#
# [*enable_registrator*]
#   Enable registrator, registrator will register the services which expose by
#   docker containers on service discovery tools like consul, etc.
#
class rjil::docker (
  $containers         = {},
  $registry_url       = undef,
  $enable_registrator = true,
) {

  ##
  # Install and setup docker on hosts
  ##
  include ::docker

  ##
  # registrator should be running on all nodes which handles
  # registoring/deregistoring the services per node
  ##
  ::docker::run {'registrator':
    image   => 'gliderlabs/registrator:latest',
    restart => 'always',
    command => '-internal consul://localhost:8500',
    volumes => ['/var/run/docker.sock:/tmp/docker.sock'],
    net     => 'host',
  }

  ##
  # First to start registrator and then other containers
  ##
  Docker::Run<| title == 'registrator' |> -> Rjil::Docker::Container<| |>

  #create_resources('::docker::image',$images,{image_tag => $version})
  create_resources('rjil::docker::container', $containers, {registry => $registry_url})

}
