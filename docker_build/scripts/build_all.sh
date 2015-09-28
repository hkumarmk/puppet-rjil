#!/bin/bash
dir=$(dirname $0)
cd $dir
# build base image first
./docker_build.sh
for i in `ls ../containers` ; do
  case "$i" in
    base)
      echo "base image already built"
      ;;
    keystone)
      ./docker_build.sh keystone 5000,35357 10
      ;;
    db)
      ./docker_build.sh db 3306 10
      ;;
    memcached)
      ./docker_build.sh memcached 11211 10
      ;;
    consul)
      echo "WARNING, consul image is not used at this moment"
#      ./docker_build.sh consul 8500 10
      ;;
    *)
      echo "$i not supported at this moment"
  esac
done
# remove all unnecessary images
for i in `docker images| awk '/^<none>/ {print $3}'`; do
  echo "removing $i";
  docker rmi $i;
done
