#
# Class rjil::db::container
#
class rjil::db::container (
  $mysql_root_pass,
  $mysql_datadir        = '/data',
  $docker_image_url     = undef,
  $docker_image_version = 'latest', # this need to be changed without default, so it is mandate to provide version (for upgrade)
) {

  if $docker_image_url {
    $docker_image = "${docker_image_url}:${docker_image_version}"
  }


  ##
  # Only provision container, if it need to be, - if you are not using
  # containers, or if you run this class within the container itself to
  # configure db                 
  ##
  rjil::docker::container {'db':
    tag             => 'docker_host',
    image_full_name => $docker_image,
    expose          => [3306], 
    env             => ["MYSQL_ROOT_PASSWORD=${mysql_root_pass}"],
    volumes         => ["${mysql_datadir}:${mysql_datadir}", '/etc/mysql:/etc/mysql']
  }                            
}
