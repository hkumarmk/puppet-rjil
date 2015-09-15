#!/bin/bash
#

wait_time=${wait_time:-10}
##
# if consul_discovery_token is set, write it to factor
##
if [ $consul_discovery_token ]; then
  echo 'consul_discovery_token='${consul_discovery_token} > /etc/facter/facts.d/consul.txt
fi

##
# create fact for container_name if its there
##
if [ $container_name ]; then
  echo 'container_name='${container_name} > /etc/facter/facts.d/container_name.txt
fi

##
# Initial configuration of system done by puppet
##
while true; do
  echo "`date` | Initial Configuration Starting"
  puppet apply --detailed-exitcodes /site.pp
  ret_code=$?
  #  python -m jiocloud.orchestrate update_own_status puppet_service $ret_code
  if [[ $ret_code = 1 || $ret_code = 4 || $ret_code = 6 ]]; then
    echo "`date` | Puppet failed with return code ${ret_code}"
    sleep $wait_time
    break
  fi
done
##
# Now run maintain.sh, to run validation continuously and if failed, run puppet.
##
if [ -f /maintain.sh ]; then
  mkdir -p /var/log/docker/${container_name}/
  nohup bash /maintain.sh 2>&1 >> /var/log/docker/${container_name}/maintain.log &
fi

# Run the application
exec "$@"
