_: {
  # ============================================================================
  # Networking
  # ============================================================================

  # Keep NetworkManager up for the whole of an activation.
  #
  # By default a changed NetworkManager unit is stopped before the new
  # configuration is activated and only started again at the very end. That
  # leaves the machine without network for the entire activation while the CIFS
  # shares from filesystems.nix are still mounted, so every stat() on one of
  # them blocks in D state until the CIFS layer gives up (~180s per share).
  # Anything walking the mount table during activation then hangs: first
  # systemd-tmpfiles, and after that Home Manager (the zen-browser activation
  # runs `lsof`, which stats every mount point). Activation stalls for minutes,
  # and the only thing that could recover it — NetworkManager — is exactly what
  # is waiting to be started.
  #
  # With stopIfChanged = false the unit is instead restarted once, after the new
  # configuration is in place, so the shares stay alive throughout.
  systemd.services.NetworkManager.stopIfChanged = false;

  networking = {
    networkmanager = {
      enable = true;
    };

    # Firewall
    firewall = {
      allowedTCPPorts = [];
    };
  };
}
