{
  config,
  osConfig,
  ...
}: {
  programs.keepassxc = {
    enable = true;
  };
  # Rendered by sops (system/shared/modules/keepassxc.nix) because it embeds
  # the KeeShare private key; ./keepassxc.ini is the template.
  xdg.configFile = {
    "keepassxc/keepassxc.ini".source =
      config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."keepassxc.ini".path;
  };
}
