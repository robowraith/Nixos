{hostname, ...}: {
  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    hostName = hostname;

    # IP via DHCP (NetworkManager); pin 192.168.1.111 with a DHCP
    # reservation in the router

    # Firewall
    firewall.allowedTCPPorts = [];
  };
}
