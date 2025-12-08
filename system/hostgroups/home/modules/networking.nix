{...}: {
  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    networkmanager.enable = true;
    defaultGateway = "192.168.1.1";
    nameservers = ["192.168.1.3"];

    # Firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [22];
    };
  };
}
