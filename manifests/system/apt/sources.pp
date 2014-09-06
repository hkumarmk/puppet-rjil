## Define rjil::system::apt::sources
define rjil::system::apt::sources (
  $location,
  $repos          = 'main',
  $key            = undef,
  $key_server     = undef,
  $key_source     = undef,
  $key_content    = undef,
  $local_repo_ip  = undef,
  $include_src    = false,
  $architecture   = 'amd64',
  $release	  = 'trusty',
  $active_sources = undef,
) {
  if member($active_sources,$name) {
    ::apt::source { $name:
	location     => $location,
	repos        => $repos,
	include_src  => $include_src,
	architecture => $architecture,
	release	     => $release,
        key          => $key,
        key_server   => $key_server,
        key_source   => $key_source,
        key_content  => $key_content,
    }
  }
}
