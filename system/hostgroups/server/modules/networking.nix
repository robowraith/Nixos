{username, ...}: {
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

  # Key-only, no root (system/shared); only the host's admin user may log in
  services.openssh.settings.AllowUsers = [username];
}
