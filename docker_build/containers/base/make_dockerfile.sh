#!/bin/bash
cat <<EOF > Dockerfile
FROM ${base_image:-ubuntu:trusty}
MAINTAINER ${maintainer:-'Jiocloud'}
COPY build.sh /
COPY site.pp /
RUN chmod 755 /build.sh
RUN /build.sh
EOF
