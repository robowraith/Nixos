{
  inputs,
  stateVersion,
  username,
  ...
}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.nix-index-database.homeModules.nix-index
    ./modules
    ./programs
  ];

  home = {
    inherit username stateVersion;
    homeDirectory = "/home/${username}";
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    BROWSER = "vivaldi";
    PAGER = "less -R";
    LANG = "de_DE.UTF-8";
  };

  # Enable fontconfig
  fonts.fontconfig.enable = true;

  # Enable XDG desktop integration
  xdg.enable = true;
  xdg.mime.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
