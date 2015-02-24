require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::db' do

  let :hiera_data do
    {
      'rjil::db::mysql_datadir'   => '/tmp/mysql',
      'rjil::db::mysql_root_pass' => 'testpass',
      'rjil::db::dbs'             => { 'nova' => { 'db' => 'testdb', 'user' => 'testuser', 'pass' => 'twst' }, },
      'rjil::db::repl_pass'       => 'passwd'
    }
  end

  let(:facts) do
    {
      :osfamily       => 'Debian',
      :processorcount => '40',
      :root_home      => '/etc/mysql',
    }
  end

  context 'with master' do
    let :params do
      {
        :is_master => true,
      }
    end
    it do
      should contain_class('mysql::server').with(
        {
          'root_password'    => 'testpass',
          'override_options' => {'mysqld'  =>
            {
              'max_connections' => '1024',
              'datadir'         => '/tmp/mysql',
              'bind-address'    => '0.0.0.0',
              'server-id'       => '0',
              'log_bin'         => 'mysql-bin.log',
              'binlog_format'   => 'mixed',
              'sync_binlog'     => '1',
            }
          },
        }
      )
    end
  end
  context 'with slave, no data disk' do
    it 'should contain default resources' do
      should contain_file('/etc/consul/mysql.json').with_content(/\"port\": 3306/)
      should contain_file('/usr/lib/jiocloud/tests/mysql.sh')
      should contain_class('mysql::server').with(
        {
          'root_password'    => 'testpass',
          'override_options' => {'mysqld'  =>
            {
              'max_connections' => '1024',
              'datadir'         => '/tmp/mysql',
              'bind-address'    => '0.0.0.0',
              'server-id'       => '0',
              'log_bin'         => 'mysql-bin.log',
              'binlog_format'   => 'mixed',
              'sync_binlog'     => '1',
              'read_only'       => true,
              'relay_log'       => 'mysql-relay-bin.log',
            }
          },
        }
      )
      should contain_file('/tmp/mysql').with(
        {
          'ensure'  => 'directory',
          'owner'   => 'mysql',
          'group'   => 'mysql',
        }
      )
      should contain_exec('mysql_install_db').with(
        {
          'command'   => 'mysql_install_db --datadir=/tmp/mysql --user=mysql',
          'creates'   => '/tmp/mysql/mysql',
        }
      )
      should_not contain_package('xfsprogs')
      should_not contain_exec('mkfs_/dev/sdb')
      should_not contain_file_line('fstab_/dev/sdb')
      should_not contain_exec('mount_/dev/sdb')
      should contain_file('/etc/mysql/debian.cnf').with(
        {
          'ensure' => 'link',
          'target' => '/etc/mysql/.my.cnf',
        }
      )
      should contain_mysql_user('monitor@127.0.0.1').with(
        {
          'ensure'        => 'present',
          'password_hash' => '*1975D095AC033CAF4E1BF94F7202A9BBFEEB66F1',
          'require'       => 'File[/root/.my.cnf]',
        }
      )

      should contain_mysql_grant('monitor@127.0.0.1/*.*').with(
        {
          'ensure'     => 'present',
          'options'    => ['GRANT'],
          'privileges' => ['USAGE'],
          'user'       => 'monitor@127.0.0.1',
          'table'      => '*.*',
          'require'    => 'Mysql_user[monitor@127.0.0.1]',
        }
      )

      should contain_mysql_user('repl@%').with(
        {
          'ensure'        => 'present',
          'password_hash' => '*A424E797037BF97C19A2E88CF7891C5C2038C039',
          'require'       => 'File[/root/.my.cnf]',
        }
      )

      should contain_mysql_grant('repl@%/*.*').with(
        {
          'ensure'     => 'present',
          'options'    => ['GRANT'],
          'privileges' => ['REPLICATION SLAVE'],
          'user'       => 'repl@%',
          'table'      => '*.*',
          'require'    => 'Mysql_user[repl@%]',
        }
      )
    end
  end


  describe 'with mysql_data_disk' do

    let :params do
      {
        :mysql_data_disk     => '/dev/sdb',
      }
    end
    it 'should contain mysql_data_disk specific resources' do
      should contain_package('xfsprogs').with(
        {
          'ensure' => 'present'
        }
      )
      should contain_exec('mkfs_/dev/sdb').with_command( /mkfs.xfs -f -d agcount=40 -l[\s\t]+size=1024m -n size=64k \/dev\/sdb/ )
      should contain_file_line('fstab_/dev/sdb').with(
        {
          'line' => '/dev/sdb /tmp/mysql xfs rw,noatime,inode64 0 2',
          'require' => 'Exec[mkfs_/dev/sdb]',
        }
      )
      should contain_exec('mount_/dev/sdb').with(
        {
          'command'   => 'mount /dev/sdb',
          'unless'    => 'df /tmp/mysql | grep /dev/sdb',
          'require'   => 'File_line[fstab_/dev/sdb]',
        }
      )
      should contain_exec('mysql_install_db').with(
        {
          'command'   => 'mysql_install_db --datadir=/tmp/mysql --user=mysql',
          'creates'   => '/tmp/mysql/mysql',
          'unless'    => 'test -d /tmp/mysql/mysql',
          'require'   => ['Package[mysql-server]','Exec[mount_/dev/sdb]'],
        }
      )
      should_not contain_exec('mysql_install_db').with(
        {
          'require' => 'Package[mysql-server]',
        }
      )
    end
  end
end
