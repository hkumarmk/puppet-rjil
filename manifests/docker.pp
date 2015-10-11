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

  if ! empty($containers) {
    ##
    # registrator should be running on all nodes which handles
    # registoring/deregistoring the services per node. At least one docker
    # container should be running before registrator run fine (may be a bug
    # in registrator, will need to check).
    ##
    ::docker::run {'registrator':
      image   => "${registry_url}/registrator:latest",
      restart => 'always',
      command => '-internal consul://localhost:8500',
      volumes => ['/var/run/docker.sock:/tmp/docker.sock'],
      net     => 'host',
    }

    ##
    # First to start other containers and then start registrator
    ##
    Rjil::Docker::Container<| |> ->  Docker::Run<| title == 'registrator' |>

    #create_resources('::docker::image',$images,{image_tag => $version})
    create_resources('rjil::docker::container', $containers, {common_volumes => $container_common_volumes, registry => $registry_url})
  }

  ##
  # Create containers log directory
  ##
  file {'/var/log/containers':
    ensure => 'directory',
  }

}
