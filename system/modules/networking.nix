{ config, lib, pkgs, ... }:

{
  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    hostName = "reason";
    networkmanager.enable = true;

    # Static IP configuration
    # Note: Adjust the interface name based on your hardware
    # Use `ip link` to find your actual interface name
    interfaces.enp7s0 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "192.168.1.111";
        prefixLength = 24;
      }];
    };

    defaultGateway = "192.168.1.1";
    nameservers = [ "192.168.1.3" ];

    # Firewall
    firewall.allowedTCPPorts = [ 22 ];
  };
}
