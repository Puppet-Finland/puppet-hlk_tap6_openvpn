# puppet-hlk_tap6_openvpn

A module that configures OpenVPN for tap-windows6 HLK tests. Tap device is used
in p2p mode. By default this means that Windows assigns link-local IPv4 and IPv6
address to the TAP adapter interface. While this works, it does not work for HLK
tests as there won't be any default IPv6 gateway which the tests require.
Therefore you need to configure static IPv4 and IPv6 settings for the adapter.
While it would be possible to do this configuration using OpenVPN config
directives that would add some delay when bring up the tunnel, which in turn
can cause tests failures.
