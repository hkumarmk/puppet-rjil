#
#
#
define rjil::docker::container (
  $image_name             = $name,
  $registry               = undef,
  $image_version          = 'latest',
  $image_full_name        = undef,
  $pull_on_start          = true,
  $restart                = 'always',
  $env                    = [],
  $net                    = 'host',
  $tty                    = false,
  $detach                 = true,
  $expose                 = [],
  $ports                  = [],
  $volumes                = [],
  $common_volumes         = [],
  $mount_log_volume       = true,
  $mount_service_check_volume  = true,
  $consul_check_scripts   = undef,
  $consul_check_ttls      = undef,
  $consul_check_intervals = '10s',
  $consul_service_names   = $name,
  $consul_service_tags    = undef,
  $privileged             = false,
) {

  ##
  # Mount /usr/lib/jiocloud/tests/service_checks across the containers so consul will be able to run
  # service check scripts installed under this directory.
  ##
  if $mount_service_check_volume {
    include rjil::test::base

    $jiocloud_volume = ['/usr/lib/jiocloud/tests/service_checks:/usr/lib/jiocloud/tests/service_checks']
  } else {
    $jiocloud_volume = []
  }

  ##
  # Mount log directories from docker_host - /var/log/containers/${name}  of
  # docker host will be mounted to /var/log of the container.
  ##
  if $mount_log_volume {
    file { "/var/log/containers/${name}":
      ensure => 'directory',
    }

    $log_volume = ["/var/log/containers/${name}:/var/log/"]
  } else {
    $log_volume = []
  }

  ##
  # merge common volumes and volumes - common volumes is the volumes which will
  # be attached to all containers in the docker host - this is helpful for dev
  # environment to share the development folder between docker host and
  # container so changing the data in docker host will cause the change added on
  # all containers in the docker host. Combining with vagrant it is going to be
  # very helpful.
  ##
  $all_common_volumes = concat($common_volumes, $log_volume, $jiocloud_volume)
  $all_volumes = union($all_common_volumes, $volumes)

  ##
  # if consul_service_names is a hash, then create multiple environment
  # variables out of it.
  # if it is string, then there is only one variable
  ##
  if is_hash($consul_service_names) {
    $env_service_names=split(strip(inline_template("<% @consul_service_names.each do |k, v|%> <%= \"SERVICE_#{k}_NAME=#{v}\" %> <% end %>")),' +')
  } else {
    $env_service_names=["SERVICE_NAME=${consul_service_names}"]
  }


  if is_hash($consul_check_scripts) {
    $env_consul_check_scripts=split(strip(inline_template("<% @consul_check_scripts.each do |k, v|%> <%= \"SERVICE_#{k}_CHECK_SCRIPT=\'#{v}\'\" %> <% end %>")),' +')
  } else {
    $env_consul_check_scripts=["SERVICE_CHECK_SCRIPT='${consul_check_scripts}'"]
  }

  if is_hash($consul_check_intervals) {
    $env_consul_check_intervals=split(strip(inline_template("<% @consul_check_intervals.each do |k, v|%> <%= \"SERVICE_#{k}_CHECK_INTERVAL=#{v}\" %> <% end %>")),' +')
  } else {
    $env_consul_check_intervals=["SERVICE_CHECK_INTERVAL=${consul_check_intervals}"]
  }

  if is_hash($consul_check_ttls) {
    $env_consul_check_ttls=split(strip(inline_template("<% @consul_check_ttls.each do |k, v|%> <%= \"SERVICE_#{k}_CHECK_TTL=#{v}\" %> <% end %>")),' +')
  } else {
    $env_consul_check_ttls=["SERVICE_CHECK_TTL=${consul_check_ttls}"]
  }

  if is_hash($consul_service_tags) {
    $env_consul_service_tags=split(strip(inline_template("<% @consul_service_tags.each do |k, v|%> <%= \"SERVICE_#{k}_TAGS=#{v}\" %> <% end %>")),' +')
  } else {
    $env_consul_service_tags=["SERVICE_TAGS=${consul_service_tags}"]
  }

  $env_1 = concat($env_service_names, $env_consul_check_scripts, $env_consul_check_intervals, $env_consul_check_ttls, $env_consul_service_tags, $env)
  $env_orig = union($env_1, ["container_name=${name}", "consul_discovery_token=${::consul_discovery_token}", "env=${::env}"])

  ##
  # either image_full_name or image_name, registry, and image_version must be
  # provided
  ##

  if $image_full_name {
    $image_orig = $image_full_name
  } elsif ($image_name) and ($registry) and (image_version) {
    $image_orig = "${registry}/${image_name}:${image_version}"
  } else {
    fail("Either image_full_name or image_name, registry, image_version must be provided")
  }

  if !empty($expose) {
    $expose_orig = $expose

    if !empty($ports) {
      $ports_orig = $ports
    } else {
      $ports_orig = $expose
    }
  } else {
    if !empty($ports) {
      $ports_orig = $ports
      $expose_orig = $ports
    }
  }

  ::docker::run {$name:
    image         => $image_orig,
    pull_on_start => $pull_on_start,
    restart       => $restart,
    env           => $env_orig,
    net           => $net,
    tty           => $tty,
    detach        => $detach,
    expose        => $expose_orig,
    ports         => $ports_orig,
    volumes       => $all_volumes,
    privileged    => $privileged,
  }

}
