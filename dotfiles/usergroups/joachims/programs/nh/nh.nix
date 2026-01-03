{config, ...}: {
  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/nixos";
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";
    };
  };
}
