# @summary Install OpenVPN and ensure that OpenVPNService is running and enabled
#
class hlk_tap6_openvpn {

  # This code is a much simplified version of what is in puppet-openvpn:
  #
  # https://github.com/Puppet-Finland/puppet-openvpn
  #
  package { 'openvpn':
    ensure   => 'present',
    provider => 'chocolatey',
    require  => Class['::chocolatey'],
  }

  service { 'openvpn':
    ensure  => 'running',
    enable  => true,
    name    => 'openvpnservice',
    require => Package['openvpn'],
  }
}
