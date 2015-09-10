#!/bin/bash
cat <<BUILD > build.sh
#!/bin/bash
if [ -n "${docker_http_proxy}" ]; then
    export http_proxy=${docker_http_proxy}
fi

if [ -n "${docker_https_proxy}" ]; then
  export https_proxy=${docker_https_proxy}
fi

export no_proxy=${no_proxy:-'127.0.0.1,169.254.169.254,localhost,consul,jiocloud.com'}

while true ; do
  puppet apply --detailed-exitcodes /site.pp --tags package; rv=\$?
  if [[ \$rv = 1 || \$rv = 4 || \$rv = 6 ]]; then
    echo "\`date\` Puppet failed. Will retry in 5 seconds"
    sleep 5
  else
    break
  fi
done
apt-get clean
BUILD
