## Class rjil::system::apt
## Purpose: configure apt sources

class rjil::system::apt (
  $active_sources = [],
) {

  ## All package operations should follow apt::source
  Apt::Source<||> -> Package<||>

  ## Define $sources which contains all apt repo details.
  ## Only sources which have entries in active_sources are enabled.
  $sources = {
    trusty  => {
      location => 'http://in.archive.ubuntu.com/ubuntu',
      repos    => 'main restricted universe multiverse',
    },
    trusty-updates => {
      location  => 'http://in.archive.ubuntu.com/ubuntu',
      release   => 'trusty-updates',
      repos => 'main restricted universe multiverse',
    },
    puppetlabs => {
      location => 'http://apt.puppetlabs.com',
      repos => 'main dependencies',
      key => 4BD6EC30,
      key_content => '-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQINBEw3u0ABEAC1+aJQpU59fwZ4mxFjqNCgfZgDhONDSYQFMRnYC1dzBpJHzI6b
fUBQeaZ8rh6N4kZ+wq1eL86YDXkCt4sCvNTP0eF2XaOLbmxtV9bdpTIBep9bQiKg
5iZaz+brUZlFk/MyJ0Yz//VQ68N1uvXccmD6uxQsVO+gx7rnarg/BGuCNaVtGwy+
S98g8Begwxs9JmGa8pMCcSxtC7fAfAEZ02cYyrw5KfBvFI3cHDdBqrEJQKwKeLKY
GHK3+H1TM4ZMxPsLuR/XKCbvTyl+OCPxU2OxPjufAxLlr8BWUzgJv6ztPe9imqpH
Ppp3KuLFNorjPqWY5jSgKl94W/CO2x591e++a1PhwUn7iVUwVVe+mOEWnK5+Fd0v
VMQebYCXS+3dNf6gxSvhz8etpw20T9Ytg4EdhLvCJRV/pYlqhcq+E9le1jFOHOc0
Nc5FQweUtHGaNVyn8S1hvnvWJBMxpXq+Bezfk3X8PhPT/l9O2lLFOOO08jo0OYiI
wrjhMQQOOSZOb3vBRvBZNnnxPrcdjUUm/9cVB8VcgI5KFhG7hmMCwH70tpUWcZCN
NlI1wj/PJ7Tlxjy44f1o4CQ5FxuozkiITJvh9CTg+k3wEmiaGz65w9jRl9ny2gEl
f4CR5+ba+w2dpuDeMwiHJIs5JsGyJjmA5/0xytB7QvgMs2q25vWhygsmUQARAQAB
tEdQdXBwZXQgTGFicyBSZWxlYXNlIEtleSAoUHVwcGV0IExhYnMgUmVsZWFzZSBL
ZXkpIDxpbmZvQHB1cHBldGxhYnMuY29tPokCPgQTAQIAKAIbAwYLCQgHAwIGFQgC
CQoLBBYCAwECHgECF4AFAk/x5PoFCQtIMjoACgkQEFS3okvW7DAIKQ/9HvZyf+LH
VSkCk92Kb6gckniin3+5ooz67hSr8miGBfK4eocqQ0H7bdtWjAILzR/IBY0xj6OH
KhYP2k8TLc7QhQjt0dRpNkX+Iton2AZryV7vUADreYz44B0bPmhiE+LL46ET5ITh
LKu/KfihzkEEBa9/t178+dO9zCM2xsXaiDhMOxVE32gXvSZKP3hmvnK/FdylUY3n
WtPedr+lHpBLoHGaPH7cjI+MEEugU3oAJ0jpq3V8n4w0jIq2V77wfmbD9byIV7dX
cxApzciK+ekwpQNQMSaceuxLlTZKcdSqo0/qmS2A863YZQ0ZBe+Xyf5OI33+y+Mr
y+vl6Lre2VfPm3udgR10E4tWXJ9Q2CmG+zNPWt73U1FD7xBI7PPvOlyzCX4QJhy2
Fn/fvzaNjHp4/FSiCw0HvX01epcersyun3xxPkRIjwwRM9m5MJ0o4hhPfa97zibX
Sh8XXBnosBQxeg6nEnb26eorVQbqGx0ruu/W2m5/JpUfREsFmNOBUbi8xlKNS5CZ
ypH3Zh88EZiTFolOMEh+hT6s0l6znBAGGZ4m/Unacm5yDHmg7unCk4JyVopQ2KHM
oqG886elu+rm0ASkhyqBAk9sWKptMl3NHiYTRE/m9VAkugVIB2pi+8u84f+an4Hm
l4xlyijgYu05pqNvnLRyJDLd61hviLC8GYU=
=qHKb
-----END PGP PUBLIC KEY BLOCK-----'
    },
    ceph => {
      location => 'http://ceph.com/debian',
      repos => 'main',
    },
    rustedhalo => {
      location => 'http://jiocloud.rustedhalo.com/ubuntu/',
      repos => 'main',
      key => '85596F7A',
      key_content => '-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQENBFM0FdsBCADbcuhgf4ny6HQXSCrskXK3hp8HUA4UbW9xIO/fqUzKTvxRuwUR
yRZHXVdCCaLOD8En+h4fnAs2PY3ueVfcIDt9DsJcmqWE+cbFG191Yw8hQV/MtxXU
YNAS6oKOwMheC3BtxdbplJ4hbg065m38wPmcgt/rJiAQZBxrKggCHTvIQunvJnmG
/7OMuwhkzewEAaG5E1mmdVq+IMJAg0ltMiRANASo07wrB0At4q62ozBomua6Hk3s
69ie5ZGiQtyIOgB1mO4RwxS0MoMd+ffq6Kyc8GPoM9EFj4zYGIyOZBa4YqI9cs9A
88E5910lHNx8p2wZCsN+Z00IDN3c6nGmHrzNABEBAAG0Kkppb0Nsb3VkIFJlcG9z
aXRvcnkgPHN1cHBvcnRAamlvY2xvdWQuY29tPokBOAQTAQIAIgUCUzQV2wIbAwYL
CQgHAwIGFQgCCQoLBBYCAwECHgECF4AACgkQhgQCvoVZb3oKVwf+Pr3hBs1h5oOk
VFHwQ/whCcnLjdY1so9wVeZ0TsZVRTrepyKB4Bi+yy4xtYZ572JLbORqRIfdOTgE
06cagaoi2Mc1e5sW/l0ifOvfjlrxIECMX4ftL2igZ7Cu4GB8+WmuDdHpsTdi1Fvx
9cn2eHAylHS3oblwoKpdfiHLPkP0Dt5aJFKOyBQfDPhjX4LF0S0aC0Zg43jNIZdf
nnC71P2+i5WwvljJV2+DTtp3/ImBMKVKgAISxOtBsA5PC+yP6X4lsUUwEP4amti8
jnq2HAjKkpM3UTAWLbHN3x6O2Mg+OIvjYUhrbYeHqQEQurUoPUx2FjZhrXDM/Cxg
tnaES5wRqLkBDQRTNBXbAQgAs4OQ1KlirGpiZC4hEvfmrkBKiJUk1sxsRzqqatkv
Ul5ay3DWoknYO+C7RIzYTwMQ9lv/QwJA2T+FpYykiu6gg872W5aje9xqg98z9DTM
C2lZ79yUMNiMNdKr6Zd05Q6zz0EQVaTMwrYEb+DOW0H8ka7HJA2MJc/ot0Bf2G2A
uavopMiikaVX67901qvHKqQMFgFzbe0C16poK057W3iFEnYAYTzJ6sLhCukfMkwk
6cIApeCEDz9d1tq5aiYcgXhnhnLnXBR9nUlI5qdfU/6+Nmcgh+izjtQp+U5cKHhl
YaiPfbVLQVUg/jbhem0XZuXJ9LdaNoeDdG+7KP7s+N+fIwARAQABiQEfBBgBAgAJ
BQJTNBXbAhsMAAoJEIYEAr6FWW96QewH/20zMCYcDgt8AoRJsyhLPLw8Xa8N57YD
EJfNUKA/74UrUSiLNktXzOVRLa1vAp5kdd9x6HNg5C0bt8kjvYzTvVChRBGt7NRg
SViL4sowyCFpT23JhHRajMmiJPigG+c4gjIJF4DbnpSG8WPC3jDPV891EZCodmaz
klc+BnhnZrb4FcB04RdQ/WXgVshDCzVQhmdIEILGKYHMTjlK/HkV6YqH7l7+jRvJ
phmH35+GJQumLfXWlvDchtBjUTo5ZDCa7TWhwhXZoFg5nxadQDX4TwHhZBQH1TX5
Chk4NnD90SYZt36sTLITe5O/BgYlRMqVo+bVj0tmjMJP/B4PZjABX7A=
=iZW7
-----END PGP PUBLIC KEY BLOCK-----'
    }
  }

  ## two settings to be overrided here in hiera
  ## apt::purge_sources_list: true, apt::purge_sources_list_d: true
  include ::apt

  ## Create apt source.list
  create_resources('rjil::system::apt::sources',$sources, {active_sources => $active_sources} )

}

