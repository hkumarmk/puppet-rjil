#!/bin/bash
set -e
function fail {
  echo "CRITICAL: $@"
  exit 2
}

if [ -f /root/openrc ]; then
  source /root/openrc
  neutron net-list || fail 'neutron net-list failed'
  neutron net-create testnet || fail 'neutron net-create failed'
  netid=`neutron net-list | awk '/[a-z][a-z]*[0-9][0-9]*/ {print $2}' | head -1`
  neutron subnet-create $netid 10.0.0.0/24 || fail 'neutron subnet-create failed'
  neutron port-create $netid || fail 'neutron port-create failed'
  for port in `neutron port-list | awk '/[a-z][a-z]*[0-9][0-9]*/ {print $2}'`; do
    neutron port-delete $port || fail 'neutron port-delete failed'
  done
  for net in `neutron net-list | awk '/[a-z][a-z]*[0-9][0-9]*/ {print $2}'`; do
    neutron net-delete $net || fail 'neutron net-delete failed'
  done
else
  echo 'Critical: Openrc does not exist'
  exit 2
fi
