#!/bin/bash
export registry='localhost:5000'
version=${version:-latest}
default_base_image="base:${version}"

if [ -n "$registry" ]; then
  base_image="${registry}/${base_image:-$default_base_image}"
else
  base_image=${base_image:-$default_base_image}
fi
cat <<EOF > Dockerfile
FROM ${base_image}
MAINTAINER ${maintainer:-'Jiocloud'}
COPY site.pp build.sh /
# Set the locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN bash /build.sh


ENTRYPOINT ["/usr/bin/runsvdir"]
CMD ["-P", "/etc/service"]
EOF
for port in `echo $ports | sed 's/,/ /g'`; do
  echo "EXPOSE ${port}" >> Dockerfile
done
