{hostname, ...}: {
  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    hostName = hostname;

    # Static IP configuration
    # Note: Adjust the interface name based on your hardware
    # Use `ip link` to find your actual interface name
    interfaces.enp7s0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.1.";
          prefixLength = 24;
        }
      ];
    };

    # Firewall
    firewall.allowedTCPPorts = [];
  };
}
