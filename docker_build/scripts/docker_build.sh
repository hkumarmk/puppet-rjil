#!/bin/bash
# Just temporary stuffs to add appropriate variables, will be removed later
export git_protocol=https
export module_git_cache=http://jiocloud.rustedhalo.com:8080/job/puppet-jiocloud-cache/lastSuccessfulBuild/artifact/cache.tar.gz
export env=build
export registry='localhost:5000'
export puppet_modules_source_repo=https://github.com/hkumarmk/puppet-rjil
export puppet_modules_source_branch=containers
export name=base
version=${version:-latest}

container_name=${1:-$name}
export ports=${2:-${service_ports:-0}}

tmp=`mktemp -d`

# order of below cp commands are important, so in case of any override for the
# below files is possible for specific container
cp -fr make_build.sh entrypoint.sh  make_dockerfile.sh $tmp/
cp -fr $(pwd)/../containers/${container_name}/* $tmp/
pushd $tmp
bash make_build.sh
bash make_dockerfile.sh
if [ -n "$registry" ]; then
  sudo -E docker build --force-rm=true -t ${registry}/${container_name}:${version} .
  sudo -E docker push ${registry}/${container_name}:${version}
else
  sudo -E docker build --force-rm=true -t ${container_name}:${version} .
fi

rm -fr $tmp