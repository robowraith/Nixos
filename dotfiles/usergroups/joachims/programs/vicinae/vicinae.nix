{config, ...}: {
  services.vicinae = {
    enable = true;
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
