#!/bin/bash
# Just temporary stuffs to add appropriate variables, will be removed later
export env=${env:-build}
export registry=${registry:-'localhost:5000'}
export name=base
version=${version:-latest}


container_name=${1:-$name}
export ports=${2:-${service_ports:-0}}
export entrypoint_args=${3:-${entrypoint_args:-10}}

tmp=`mktemp -d`

# order of below cp commands are important, so in case of any override for the
# below files is possible for specific container
cp -fr * $tmp/
cp -fr $(pwd)/../containers/${container_name}/* $tmp/
pushd $tmp
bash make_build.sh
bash make_dockerfile.sh
if [ -n "$registry" ]; then
  sudo -E docker build --no-cache --force-rm=true -t ${registry}/${container_name}:${version} .
  sudo -E docker push ${registry}/${container_name}:${version}
else
  sudo -E docker build --no-cache --force-rm=true -t ${container_name}:${version} .
fi

rm -fr $tmp