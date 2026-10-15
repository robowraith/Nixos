_: {
  # ============================================================================
  # Networking
  # ============================================================================
  # systemd-networkd instead of NetworkManager; each host declares its own
  # (usually static) addressing in its networking.nix.

  networking = {
    useNetworkd = true;
    useDHCP = false;
  };
  systemd.network.enable = true;
}
