{
  config,
  username,
  ...
}: {
  # KeePassXC's config holds the KeeShare signing key, so the ini is rendered
  # by sops at activation instead of living in the (public) repo and the
  # world-readable nix store. Home Manager symlinks it into place, see
  # dotfiles/shared/programs/keepassxc/keepassxc.nix.
  sops.secrets.keepassxc_keeshare_own = {};

  sops.templates."keepassxc.ini" = {
    owner = username;
    content =
      builtins.replaceStrings
      ["@KEESHARE_OWN_KEY@"]
      [config.sops.placeholder.keepassxc_keeshare_own]
      (builtins.readFile ../../../../dotfiles/shared/programs/keepassxc/keepassxc.ini);
  };
}
