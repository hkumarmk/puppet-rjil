## Class rjil::db
## This class does below stuffs
## Install mysql server packages
## format and mount mysql_data_disk to mysql_datadir
## create mysql database if not exists
## create databases and users and grants if not exists

class rjil::db (
  $mysql_root_pass,
  $repl_pass,
  $mysql_server_package_name = 'mariadb-server',
  $mysql_datadir             =  '/data',
  $mysql_max_connections     = 1024,
  $mysql_data_disk           = undef,
  $dbs                       = {},
  $bind_address              = '0.0.0.0',
  $server_id                 = undef,
  $log_bin                   = 'mysql-bin.log',
  $is_master                 = false,
  $binlog_format             = 'mixed',
  $sync_binlog               = 1,
  $relay_log                 = 'mysql-relay-bin.log',
  $repl_user                 = 'repl',
  $master_server             = 'master.mysql.service.consul',
)  {

  ##
  # If server_id is not set, use last octet of its IP address
  ##

  if $server_id {
    $server_id_orig = $server_id
  } elsif $bind_address != '0.0.0.0' {
    $server_id_orig = regsubst($bind_address,'^(\d+)\.(\d+)\.(\d+)\.(\d+)$','\4')
  } else {
    $server_id_orig = regsubst($ipaddress,'^(\d+)\.(\d+)\.(\d+)\.(\d+)$','\4')
  }

  ##
  # This is the default mysql configuration options
  ##
  $default_mysqld_options = {
        'max_connections' => $mysql_max_connections,
        'datadir'         => $mysql_datadir,
        'bind-address'    => $bind_address,
        'server-id'       => $server_id_orig,
        'log_bin'         => $log_bin,
        'binlog_format'   => $binlog_format,
        'sync_binlog'     => $sync_binlog,
      }

  ##
  # is_master is true for the mysql master node. We run mysql master on the
  # leader node which is based on cluster_role fact which will be 'leader' for
  # cluster leader and 'follower' for followers.
  ##
  if $is_master {
    $override_mysqld_options = {}
    $consul_tags = ['master']

    ##
    # Add master data to consul kv.
    # Only collect master data after creating all dbs, users, grants but before
    # any writes from the applications (or any other scripts or something if
    # any)
    ##
    consul_kv_mysql_masterdata {'openstack':}
    Mysql_user<||> -> Consul_kv_mysql_masterdata<||>
    Mysql_grant<||> -> Consul_kv_mysql_masterdata<||>
    Mysql_database<||> -> Consul_kv_mysql_masterdata<||>
    Consul_kv_mysql_masterdata<||> -> Rjil::Jiocloud::Consul::Service<| title == 'mysql' |>
    Class['rjil::db'] -> Rjil::Service_blocker<| title == 'master.mysql' |>
  } else {
    ##
    # Do not run mysql slave block if leader_node fact is not defined. This will
    # make sure unncessary service blocker on master.mysql on mysql slaves.
    # This fact will not be set on initial puppet run and all subsequent runs
    # after the consul session creation will have this fact set.
    ##
    if $::leader_node {
      ##
      # Slave will be readonly.
      ##
      $override_mysqld_options = {
        'read_only' => true,
        'relay_log' => $relay_log,
      }
      ##
      # So you will have slave.mysql.service.consul for slaves. This is not
      # useful right now, but may be useful later.
      ##
      $consul_tags = ['slave']

      ##
      # Update the mysql slave configuration with master data - mysql slave
      # configuration need following items to be populated
      # replication user, replication password -> both are getting as params
      # Binary log file name and position -> they are getting from the consul kv
      ##
      consul_kv_mysql_slave_update{'openstack':
        repl_user => $repl_user,
        repl_password => $repl_pass,
      }

      ##
      # Make sure slave will not configure itself before master is up
      # Also make sure slave will not be configured until the consul kv for
      # masterdata is there.
      ##
      ensure_resource( 'rjil::service_blocker', 'master.mysql', {})

      ensure_resource( 'consul_kv_fail', 'services/openstack/mysql/masterdata', {})

      Consul_kv_fail['services/openstack/mysql/masterdata'] -> Consul_kv_mysql_slave_update<| title == 'openstack' |>

      Rjil::Service_blocker['master.mysql'] -> Consul_kv_mysql_slave_update<| title == 'openstack' |>
    }
  }

  $mysqld_options = merge($default_mysqld_options,$override_mysqld_options)

  ##
  # create a consul session
  ##
  consul_session{"mysql~${::hostname}":
    ensure => present,
    lockdelay => 60,
  }

  ## Setup test code

  rjil::test { 'mysql.sh': }

  ## Call db_def to create databases, users and grants
  create_resources('rjil::db::instance', $dbs)
  ## setup mysql server
  class { '::mysql::server':
    root_password    => $mysql_root_pass,
    restart          => true,
    package_name     => $mysql_server_package_name,
    override_options => {
      'mysqld' => $mysqld_options
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

  mysql_user { "monitor@${user_address}":
    ensure        => 'present',
    password_hash => mysql_password('monitor'),
    require       => File['/root/.my.cnf'],
  }

  mysql_grant { "monitor@${user_address}/*.*":
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['USAGE'],
    user       => "monitor@${user_address}",
    table      => '*.*',
    require    => Mysql_user["monitor@${user_address}"],
  }

  ##
  # This user should be anabled from all slave nodes, need to see how we add
  #   the access to specific hosts, so enabling from all hosts for now.
  ##
  mysql_user { "${repl_user}@%":
    ensure        => 'present',
    password_hash => mysql_password($repl_pass),
    require       => File['/root/.my.cnf'],
  }

  mysql_grant { "${repl_user}@%/*.*":
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['REPLICATION SLAVE'],
    user       => "${repl_user}@%",
    table      => '*.*',
    require    => Mysql_user["${repl_user}@%"],
  }

  rjil::jiocloud::consul::service { "mysql":
    port          => 3306,
    tags          => $consul_tags,
    check_command => "/usr/lib/nagios/plugins/check_mysql -H ${bind_address} -u monitor -p monitor"
  }

}
