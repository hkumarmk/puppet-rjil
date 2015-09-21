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
# [*container_common_volumes*]
#   An array of volumes which will be mounted on all containers. This is helpful
#   to share any volume between docker host and the containers, especially
#   helpful in dev environment where one just need to change the data on docker
#   host which will be available to all containers in that host. Combining with
#   vagrant, it is going to be very helpful.
#
class rjil::docker (
  $containers               = {},
  $container_common_volumes = [],
  $registry_url             = undef,
  $enable_registrator       = true,
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
  create_resources('rjil::docker::container', $containers, {common_volumes => $container_common_volumes, registry => $registry_url})

}
