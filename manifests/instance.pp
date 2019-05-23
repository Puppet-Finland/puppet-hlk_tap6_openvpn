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
# @interface_alias
#   The alias (name) for the tap-windows6 adapter. For the support machine this
#   should usually be set to 'SupportDevice0'.
# @interface_ipv4
#   The IPv4 address for the tap-windows6 adapter, including netmask in CIDR notation.
# @interface_ipv6
#   The IPv6 address for the tap-windows6 adapter, including netmask in CIDR notation.
# @interface_gw_ipv4
#   The default IPv4 gateway for the tap-windows6 adapter. Leave empty if no gateway.
# @interface_gw_ipv6
#   The default IPv6 gateway for the tap-windows6 adapter. Leave empty if no gateway.
# @param allow_address_ipv4
#   The IPv4 address or network (e.g. "172.16.5.8") from which to allow
#   connections to the remote.
#
define hlk_tap6_openvpn::instance
(
  Stdlib::IP::Address::V4           $remote,
  String                            $interface_alias,
  Stdlib::IP::Address::V4           $interface_ipv4,
  Stdlib::IP::Address::V6           $interface_ipv6,
  String                            $static_key,
  Integer                           $port = 1194,
  Optional[Stdlib::IP::Address::V4] $allow_address_ipv4 = '127.0.0.1',
  Optional[Stdlib::IP::Address::V4] $interface_gw_ipv4 = undef,
  Optional[Stdlib::IP::Address::V6] $interface_gw_ipv6 = undef,
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

  ### Configure the tap-windows6 adapter to make HLK tests go smoother
  #
  # Naming the tap-windows6 adapter as "SupportDevice0" ensures that HLK
  # controller does not try to use the support machine for running HLK tests,
  # except in the support role. This is needed because the support machine
  # _has_ to be in the machine pool.
  #
  # This renaming may fail if there are multiple tap adapters on the system.
  #
  # See https://github.com/PowerShell/NetworkingDsc/wiki/NetAdapterName
  dsc_xnetadaptername { $interface_alias:
    dsc_newname              => $interface_alias,
    dsc_interfacedescription => 'TAP-Windows Adapter V9',
  }

  dsc_xnetconnectionprofile { $interface_alias:
    dsc_interfacealias  => $interface_alias,
    dsc_networkcategory => 'Private',
  }

  # Define static IPv4 and IPv6 settings for the tap-windows6 adapter. This
  # reduces the delay when bringing up and down the connection and makes it
  # more likely that some of the more aggressively-timed HLK tests pass.
  $tap_adapter_ips = {  'IPv4' => $interface_ipv4,
                        'IPv6' => $interface_ipv6, }
  $tap_adapter_gws = {  'IPv4' => $interface_gw_ipv4,
                        'IPv6' => $interface_gw_ipv6, }

  # See https://github.com/PowerShell/NetworkingDsc/wiki/IPAddress
  #
  $tap_adapter_ips.each |$item| {
    dsc_xipaddress { "${interface_alias}-${item[0]}":
      dsc_interfacealias => $interface_alias,
      dsc_addressfamily  => $item[0],
      dsc_ipaddress      => $item[1],
    }
  }

  # See https://github.com/PowerShell/NetworkingDsc/wiki/DefaultGatewayAddress
  $tap_adapter_gws.each |$item| {
    dsc_xdefaultgatewayaddress { "${interface_alias}-${item[0]}":
      dsc_interfacealias => $interface_alias,
      dsc_addressfamily  => $item[0],
      dsc_address        => $item[1],
    }
  }
}
