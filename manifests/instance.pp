# @summary Setup OpenVPN in peer-to-peer static key mode for the purpose of HLK testing tap-windows6
#
# @param title
#   The $title of this resource becomes the basename for config and key names.
# @param remote
#   The IPv4 address of the peer. This should be an internal, non-VPN IP using
#   which the other end (remote) can be reached.
# @param static_key
#   The OpenVPN static key to use.
# @param port
#   OpenVPN server port.
# @param allow_address_ipv4
#   The IPv4 address or network (e.g. "172.16.5.8") from which to allow
#   connections to the remote.
#
define hlk_tap6_openvpn::instance
(
  Stdlib::IP::Address::V4           $remote,
  String                            $static_key,
  Integer                           $port = 1194,
  Optional[Stdlib::IP::Address::V4] $allow_address_ipv4 = '127.0.0.1'
)
{

  $identifier = $title

  # Install static key
  file { "${identifier}.key":
    name    => "C:\\Program Files\\OpenVPN\\config\\${identifier}.key",
    content => $static_key,
    require => Package['openvpn'],
    notify  => Service['openvpnservice'],
  }

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

  # Install OpenVPN config
  file { "${identifier}.ovpn":
    name    => "C:\\Program Files\\OpenVPN\\config\\${identifier}.ovpn",
    content => template('hlk_tap6_openvpn/hlk.ovpn.erb'),
    require => Package['openvpn'],
    notify  => Service['openvpnservice'],
  }
}
