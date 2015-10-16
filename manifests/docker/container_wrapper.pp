#
# Define rjil::docker::container_wrapper
#   This defined type is to provider a wrapper for container code.
#
# [*container_params*]
#   container parameters
#
# [*default_params*]
#   container default parameters which is common for all containers
#
# [*helper_class*]
#   A puppet class which can be used to provision containers rather than
#   rjil::docker::container. This is required to have additional things to be
#   performed on creating the containers.
#
# [*helper_type*]
#   Same as above, but this is going to be defined type rather than a class.
#
define rjil::docker::container_wrapper (
  $container_params = {},
  $default_params   = {},
  $helper_class     = undef,
  $helper_type      = undef,
) {
  if $helper_class {
    class { $helper_class:
      container_params => $container_params,
      default_params   => $default_params,
    }
  } elsif $helper_type {
    create_resources($helper_type, {"${name}" => {container_params => $container_params}}, {default_params => $default_params})
  } else {
    create_resources('rjil::docker::container', {"${name}" => $container_params}, $default_params)
  }
}
