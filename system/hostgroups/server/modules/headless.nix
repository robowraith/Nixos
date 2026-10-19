{lib, ...}: {
  # ============================================================================
  # Headless server defaults
  # ============================================================================
  # Servers and appliances have no desktop, no Home Manager profile and are
  # deployed from a desktop (nixos-rebuild --target-host); nothing is built
  # on the box itself. The kernel is left at the NixOS default (LTS) so it
  # always comes from the binary cache.

  documentation.enable = false;

  # nix-index's database and comma are only useful interactively; they cost
  # space on small disks
  programs = {
    nix-index.enable = lib.mkForce false;
    nix-index-database.comma.enable = lib.mkForce false;
  };

  zramSwap.enable = true;

  # Accounts come only from the config: a changed password hash in sops is
  # applied on the next deploy. With mutable users it is only used when the
  # account is first created (found when fixing yori's password on dumont).
  users.mutableUsers = false;
}
