## Class rjil::db
## This class does below stuffs
## Install mysql server packages
## format and mount mysql_data_disk to mysql_datadir
## create mysql database if not exists
## create databases and users and grants if not exists

class rjil::db (
  $mysql_root_pass,
  $mysql_server_package_name = 'mariadb-server',
  $mysql_datadir =  '/data',
  $mysql_max_connections = 1024,
  $mysql_data_disk = undef,
  $dbs = {},
  $bind_address = '0.0.0.0',
  $monitor_user = 'monitor',
  $monitor_password = 'monitor',
)  {


  ## Setup test code

  rjil::test { 'mysql.sh': }

  ## Call db_def to create databases, users and grants
  create_resources('rjil::db::instance', $dbs)
  ## setup mysql server
  class { '::mysql::server':
    root_password    => $mysql_root_pass,
    restart          => true,
    package_name     => $mysql_server_package_name,
    override_options => { 'mysqld' => {
      'max_connections' => $mysql_max_connections,
      'datadir'         => $mysql_datadir,
      'bind-address'    => $bind_address,
      }
    },
  }

  file { $mysql_datadir:
    ensure  => 'directory',
    owner   => 'mysql',
    group   => 'mysql',
    require => Class['Mysql::Server'],
  }

  ## If mysql_data_disk is setup, configure it
  if $mysql_data_disk {
    ## Make sure xfsprogs installed
    ensure_resource('package','xfsprogs',{'ensure' => 'present'})

    ## Format the disk if not formatted
    exec { "mkfs_${mysql_data_disk}":
      command => "mkfs.xfs -f -d agcount=${::processorcount} -l \
      size=1024m -n size=64k ${mysql_data_disk}",
      unless  => "xfs_admin -l ${mysql_data_disk}",
      require => Package['xfsprogs'],
    }

    ## Add fstab entry
    file_line { "fstab_${mysql_data_disk}":
      line => "${mysql_data_disk} ${mysql_datadir} xfs rw,noatime,inode64 0 2",
      path => '/etc/fstab',
      require => Exec["mkfs_${mysql_data_disk}"],
    }

    ## Mount mysql_data_disk on mysql_datadir
    exec { "mount_${mysql_data_disk}":
      command => "mount ${mysql_data_disk}",
      unless  => "df ${mysql_datadir} | grep ${mysql_data_disk}",
      require => File_line["fstab_${mysql_data_disk}"],
    }

    ## install db in case if mysql is not installed.
    exec { 'mysql_install_db':
      command   => "mysql_install_db --datadir=${mysql_datadir} --user=mysql",
      creates   => "${mysql_datadir}/mysql",
      logoutput => on_failure,
      path      => '/bin:/sbin:/usr/bin:/usr/sbin',
      unless    => [ "test -d ${mysql_datadir}/mysql" ],
      require   => [Package['mysql-server'],Exec["mount_${mysql_data_disk}"]],
    }

  } else {

    ## install db in case if mysql is not installed.
    ## FIXME: I see this code is added in master branch of puppetlabs/mysql,
    ##        Once we use that, this code should be removed.
    exec { 'mysql_install_db':
      command   => "mysql_install_db --datadir=${mysql_datadir} --user=mysql",
      creates   => "${mysql_datadir}/mysql",
      logoutput => on_failure,
      path      => '/bin:/sbin:/usr/bin:/usr/sbin',
      unless    => [ "test -d ${mysql_datadir}/mysql" ],
      require   => Package['mysql-server'],
    }
  }

  # init script of mariadb is looking for mysql cleiint configuration
  ## in /etc/mysql/debian.conf, so Make a symlink /root/.my.cnf to it

  file { '/etc/mysql/debian.cnf':
    ensure => 'link',
    target => "${::root_home}/.my.cnf",
  }

  if ($bind_address == '0.0.0.0') {
    $user_address = '127.0.0.1'
  } else {
    $user_address = $bind_address
  }

  if $user_address {
    mysql_user { "${monitor_user}@${user_address}":
      ensure        => 'present',
      password_hash => mysql_password($monitor_password),
      require       => File['/root/.my.cnf'],
    }

    mysql_grant { "${monitor_user}@${user_address}/*.*":
      ensure     => 'present',
      options    => ['GRANT'],
      privileges => ['USAGE'],
      user       => "${monitor_user}@${user_address}",
      table      => '*.*',
      require    => Mysql_user["${monitor_user}@${user_address}"],
    }
  }

  # make sure that we install mysql before our service blocker starts for the
  # case where they are on the same machine
  Class['rjil::db'] -> Rjil::Service_blocker<| title == 'mysql' |>

}
