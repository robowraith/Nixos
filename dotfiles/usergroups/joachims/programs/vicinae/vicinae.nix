{config, ...}: {
  programs.vicinae = {
    enable = true;
    # The vicinae flake module defaults this to true, which assigns
    # `programs.google-chrome.nativeMessagingHosts` — an option this Home
    # Manager version does not declare for proprietary Chrome (see the shim in
    # flake.nix). We wire up the vicinae native-messaging host for Vivaldi
    # manually in vivaldi.nix, so this integration is not needed.
    enableChromeIntegration = false;
    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = 1;
        PATH = "${config.home.homeDirectory}/.nix-profile/bin:${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin";
      };
    };
  };
}
