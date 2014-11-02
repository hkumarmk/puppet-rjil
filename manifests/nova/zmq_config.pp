##
# Class: rjil::nova::zmq_config
# Just moving nova_config for zmq configuration out of rjil::nova::controller or
# rjil::nova::compute, to support a scenario to have both compute and controller
# on same machine.
##

class rjil::nova::zmq_config (
  $rpc_backend          = 'zmq',
  $rpc_zmq_bind_address = '*',
  $rpc_zmq_contexts     = 1,
  $rpc_zmq_matchmaker   = 'oslo.messaging._drivers.matchmaker_ring.MatchMakerRing',
  $rpc_zmq_port         = 9501,
) {
  nova_config {
    'DEFAULT/rpc_zmq_bind_address': value => $rpc_zmq_bind_address;
    'DEFAULT/ring_file':            value => '/etc/oslo/matchmaker_ring.json';
    'DEFAULT/rpc_zmq_port':         value => $rpc_zmq_port;
    'DEFAULT/rpc_zmq_contexts':     value => $rpc_zmq_contexts;
    'DEFAULT/rpc_zmq_ipc_dir':      value => '/var/run/openstack';
    'DEFAULT/rpc_zmq_matchmaker':   value => $rpc_zmq_matchmaker;
    'DEFAULT/rpc_zmq_host':         value => $::hostname;
  }
}
