_: {
  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    networkmanager.enable = true;
    defaultGateway = "192.168.1.1";
    nameservers = ["192.168.1.3" "2003:cc:b706:fbeb:3ea8:2aff:fea0:5161"];

    # Firewall
    firewall = {
      allowedTCPPorts = [];
    };
  };
}
