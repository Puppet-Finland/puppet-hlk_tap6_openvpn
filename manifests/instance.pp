# @summary Setup OpenVPN in static key mode for the purpose of HLK testing tap-windows6
#
# @param vpn_ip
#   The VPN IPv4 address of this peer. Netmask of '255.255.255.0' is assumed.
#   This is also used as a part of OpenVPN config file basenames.
# @param static_key
#   The OpenVPN static key to use.
# @param remote
#   The IPv4 address of the peer. This should be an internal, non-VPN IP using
#   which the remote can reached. On the "server" node you should omit this.
# @param port
#   OpenVPN server port.
# @param allow_address_ipv4
#   The IPv4 address or network (e.g. "172.16.5.8") from which to allow
#   connections to the "server". On the "clients" this has no effect.
#
define hlk_tap6_openvpn::instance
(
  Stdlib::IP::Address::V4           $vpn_ip,
  String                            $static_key,
  Integer                           $port = 1194,
  Optional[Stdlib::IP::Address::V4] $remote = undef,
  Optional[Stdlib::IP::Address::V4] $allow_address_ipv4 = '127.0.0.1'
)
{

  # Convert the dots in the IP into dashes. May not be necessary but looks
  # nicer in a filename on Windows.
  $identifier = regsubst($vpn_ip, '\.', '-', 'G')

  # Install static key
  file { "${identifier}.key":
    name    => "C:\\Program Files\\OpenVPN\\config\\${identifier}.key",
    content => $static_key,
    require => Package['openvpn'],
    notify  => Service['openvpnservice'],
  }

  if $remote {
    # This is a "client" instance and needs to know where to connect
    $connectivity_line = "remote ${remote} ${port} udp"
  } else {
    # This is a "server" instance and needs a port number for cases where
    # multiple OpenVPN instances are running on the same server.
    $connectivity_line = "port ${port}"

    # The port also needs to be open or "clients" can't reach it
    ::windows_firewall::exception { "HLK-OpenVPN-${identifier}-in":
      ensure       => 'present',
      direction    => 'in',
      action       => 'allow',
      enabled      => true,
      protocol     => 'UDP',
      local_port   => $port,
      remote_ip    => $allow_address_ipv4,
      display_name => "HLK-OpenVPN-${identifier}-in",
      description  => "Allow HLK p2p OpenVPN connections to udp port ${port}",
    }
  }

  # Install OpenVPN config
  file { "${identifier}.ovpn":
    name    => "C:\\Program Files\\OpenVPN\\config\\${identifier}.ovpn",
    content => template('hlk_tap6_openvpn/hlk.ovpn.erb'),
    require => Package['openvpn'],
    notify  => Service['openvpnservice'],
  }
}
