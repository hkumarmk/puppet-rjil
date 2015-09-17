#
#
#
define rjil::docker::container (
  $image_name            = $name,
  $registry              = undef,
  $image_version         = 'latest',
  $image_full_name       = undef,
  $pull_on_start         = true,
  $restart               = 'always',
  $env                   = [],
  $net                   = 'host',
  $tty                   = false,
  $detach                = true,
  $expose                = [],
  $ports                 = [],
  $volumes               = [],
  $consul_check_script   = undef,
  $consul_check_ttl      = undef,
  $consul_check_interval = '10s',
  $consul_service_name   = $name,
  $consul_service_tags   = undef,
) {

  $env_orig = union($env,["container_name=${name}", "SERVICE_NAME=${consul_service_name}",
        "SERVICE_TAGS='${consul_service_tags}'", "SERVICE_CHECK_SCRIPT='${consul_check_script}'",
        "_CHECK_INTERVAL=${consul_check_interval}", "SERVICE_CHECK_TTL=${consul_check_ttl}",
        "SERVICE_NAME=${consul_service_name}", "consul_discovery_token=${::consul_discovery_token}"])

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
    volumes       => $volumes,
  }

}
