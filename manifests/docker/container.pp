#
#
#
define rjil::docker::container (
  $image_name    = $name,
  $registry      = undef,
  $image_version = 'latest',
  $image_full_name = undef,
  $pull_on_start = true,
  $restart       = 'always',
  $env           = [],
  $net           = 'host',
  $tty           = false,
  $detach        = true,
  $expose        = [],
  $ports         = [],
  $volumes       = [],
) {

  $env_orig = union($env,["container_name=${name}"])

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
