_: {
  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    networkmanager = {
      enable = true;
    };
    defaultGateway = "192.168.1.1";

    # Firewall
    firewall = {
      allowedTCPPorts = [];
    };
  };
}
