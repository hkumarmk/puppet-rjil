#!/bin/bash
release="$(lsb_release -cs)"
cat <<BUILD > build.sh
#!/bin/bash -xe
date
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

sudo mkdir -p /etc/facter/facts.d

if [ -n "${env}" ]; then
  echo 'env='${env} > /etc/facter/facts.d/env.txt
fi

if [ -n "${cloud_provider}" ]; then
  echo 'cloud_provider='${cloud_provider} > /etc/facter/facts.d/cloud_provider.txt
fi

##
# Docker build will boot the docker (temporary) containers with an isolated network,
# so docker_http_proxy/docker_https_proxy environment variable should reflect the
# ip address for docker0 or any other interface which are reachable from the
# container.
##
if [ -n "${docker_http_proxy}" ]; then
  export http_proxy=${docker_http_proxy}
fi

if [ -n "${docker_https_proxy}" ]; then
  export https_proxy=${docker_https_proxy}
fi

echo no_proxy='127.0.0.1,169.254.169.254,localhost,consul,jiocloud.com' >> /etc/environment
export no_proxy='127.0.0.1,169.254.169.254,localhost,consul,jiocloud.com'

if [ -n "${git_protocol}" ]; then
  export git_protocol="${git_protocol}"
fi
apt-get install -y --no-install-recommends wget
wget -O puppet.deb -t 5 -T 30 http://apt.puppetlabs.com/puppetlabs-release-${release}.deb
dpkg -i puppet.deb

wget -O jiocloud.deb -t 5 -T 30 http://jiocloud.rustedhalo.com/ubuntu/jiocloud-apt-${release}-testing.deb
dpkg -i jiocloud.deb
n=0
while [ \$n -le 5 ]
do
  apt-get update && apt-get install -y puppet software-properties-common puppet-jiocloud jiocloud-ssl-certificate && break
  n=\$((\$n+1))
  sleep 5
done

if [ -n "${puppet_modules_source_repo}" ]; then
  apt-get install -y git
  git clone ${puppet_modules_source_repo} /tmp/rjil
  if [ -n "${puppet_modules_source_branch}" ]; then
    pushd /tmp/rjil
    git checkout ${puppet_modules_source_branch}
    popd
  fi
  if [ -n "${pull_request_id}" ]; then
    pushd /tmp/rjil
    git fetch origin pull/${pull_request_id}/head:test_${pull_request_id}
    git config user.email "testuser@localhost.com"
    git config user.name "Test User"
    git merge -m 'Merging Pull Request' test_${pull_request_id}
    popd
  fi
  time gem install librarian-puppet-simple --no-ri --no-rdoc;
  mkdir -p /etc/puppet/manifests.overrides
  cp /tmp/rjil/site.pp /etc/puppet/manifests.overrides/
  mkdir -p /etc/puppet/hiera.overrides
  sed  -i "s/  :datadir: \/etc\/puppet\/hiera\/data/  :datadir: \/etc\/puppet\/hiera.overrides\/data/" /tmp/rjil/hiera/hiera.yaml
  cp /tmp/rjil/hiera/hiera.yaml /etc/puppet
  cp -Rf /tmp/rjil/hiera/data /etc/puppet/hiera.overrides
  mkdir -p /etc/puppet/modules.overrides/rjil
  cp -Rf /tmp/rjil/* /etc/puppet/modules.overrides/rjil/
  if [ -n "${module_git_cache}" ]
  then
    cd /etc/puppet/modules.overrides
    wget -O cache.tar.gz "${module_git_cache}"
    tar xzf cache.tar.gz
    time librarian-puppet update --puppetfile=/tmp/rjil/Puppetfile --path=/etc/puppet/modules.overrides
  else
    time librarian-puppet install --puppetfile=/tmp/rjil/Puppetfile --path=/etc/puppet/modules.overrides
  fi
  cat <<INISETTING | puppet apply --config_version='echo settings'
  ini_setting { basemodulepath: path => "/etc/puppet/puppet.conf", section => main, setting => basemodulepath, value => "/etc/puppet/modules.overrides:/etc/puppet/modules" }
  ini_setting { default_manifest: path => "/etc/puppet/puppet.conf", section => main, setting => default_manifest, value => "/etc/puppet/manifests.overrides/site.pp" }
  ini_setting { disable_per_environment_manifest: path => "/etc/puppet/puppet.conf", section => main, setting => disable_per_environment_manifest, value => "true" }
INISETTING
else
  puppet apply --config_version='echo settings' -e "ini_setting { default_manifest: path => \"/etc/puppet/puppet.conf\", section => main, setting => default_manifest, value => \"/etc/puppet/manifests/site.pp\" }"
fi
puppet apply /site.pp --tags package
apt-get clean
date
BUILD
