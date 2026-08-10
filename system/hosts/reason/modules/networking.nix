{hostname, ...}: {
  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    hostName = hostname;

    # IP via DHCP (NetworkManager); pin 192.168.1.111 with a static
    # DHCP lease in Pi-hole (dnsmasq dhcp-host on wintermute)

    # Firewall
    firewall.allowedTCPPorts = [];
  };
}
