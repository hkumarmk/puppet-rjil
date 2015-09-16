#!/bin/bash
export registry='localhost:5000'
version=${version:-latest}
default_base_image="base:${version}"

##
# Multiple arguments should be formatted
##
for arg in `echo $entrypoint_args`; do
  args="$args, \"$arg\""
done

args=`echo $args | sed 's/^ *,//'`


if [ -n "$registry" ]; then
  base_image="${registry}/${base_image:-$default_base_image}"
else
  base_image=${base_image:-$default_base_image}
fi
cat <<EOF > Dockerfile
FROM ${base_image}
MAINTAINER ${maintainer:-'Jiocloud'}
COPY site.pp /site.pp
COPY build.sh /build.sh
RUN bash /build.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD [$args]
EOF
for port in `echo $ports | sed 's/,/ /g'`; do
  echo "EXPOSE ${port}" >> Dockerfile
done
