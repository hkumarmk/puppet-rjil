#!/bin/bash
#
exec 2>&1

wait_time=${wait_time:-10}
run_puppet=1

##
# if consul_discovery_token is set, write it to factor
##
if [ -n $consul_discovery_token ]; then
  echo 'consul_discovery_token='${consul_discovery_token} > /etc/facter/facts.d/consul.txt
fi

##
# create fact for container_name if its there
##
if [ -n $container_name ]; then
  echo 'container_name='${container_name} > /etc/facter/facts.d/container_name.txt
fi

# fact for env
if [ -n $env ]; then
  echo 'env='${env} > /etc/facter/facts.d/env.txt
fi

##
# Below chunk of code will run in infinite loop which make sure this container
# and apps running in this container is up and running and configured correctly.
##
while true; do
  if [ $run_puppet -eq 1 ]; then
    echo "Running Puppet"
    puppet apply --detailed-exitcodes /site.pp
    ret_code=$?
    #  python -m jiocloud.orchestrate update_own_status puppet_service $ret_code
    if [[ $ret_code = 1 || $ret_code = 4 || $ret_code = 6 ]]; then
      echo "Puppet failed with return code ${ret_code}"
      sleep $wait_time
      continue
    else
      run_puppet=0
    fi
  fi

  echo "Running validation"
  run-parts --regex=. --verbose --exit-on-error  --report /usr/lib/jiocloud/tests/
  ret_code=$?
  if [ $ret_code -ne 0 ]; then
    run_puppet=1
  else
    sleep $wait_time
  fi
  #python -m jiocloud.orchestrate update_own_status validation_service $ret_code
done
