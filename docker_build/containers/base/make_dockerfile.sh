#!/bin/bash
cat <<EOF > Dockerfile
FROM ${base_image:-ubuntu:trusty}
MAINTAINER ${maintainer:-'Jiocloud'}
COPY maintain.sh build.sh site.pp /
RUN chmod 755 /build.sh /maintain.sh

# Set locale
RUN locale-gen en_US.UTF-8

RUN /build.sh
EOF
