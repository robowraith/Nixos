_: {
  # ============================================================================
  # Small-disk housekeeping
  # ============================================================================
  # Keep room for one more deploy on hosts with little storage (dumont: 8 GB
  # eMMC). The daily GC from system/shared still applies on top of this.

  nix.settings = {
    # Collect garbage during builds/copies when less than 512 MiB is free,
    # until 2 GiB are free again
    min-free = 512 * 1024 * 1024;
    max-free = 2048 * 1024 * 1024;
  };

  # Each generation keeps a kernel + initrd on the ESP
  boot.loader.systemd-boot.configurationLimit = 5;

  services.journald.extraConfig = ''
    SystemMaxUse=200M
  '';

  # The flake registry / NIX_PATH entry pins a full nixpkgs source (~200 MiB)
  # into the closure; it is only needed for interactive `nix shell nixpkgs#…`
  # on the box itself, which can fetch nixpkgs instead
  nixpkgs.flake = {
    setFlakeRegistry = false;
    setNixPath = false;
  };
}
