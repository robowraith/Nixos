{config, ...}: {
  home.sessionVariables.NH_SEARCH_CHANNEL = "nixos-25.11";

  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/nixos";
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";
    };
  };
}
