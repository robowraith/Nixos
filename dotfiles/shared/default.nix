{
  inputs,
  lib,
  stateVersion,
  username,
  ...
}: let
  programs-path = ./programs;

  # Recursively finds all .nix files under a given path,
  # while ignoring the `_uninstalled` directory at the top level.
  collectNixFiles = path: let
    entries = builtins.readDir path;
  in
    builtins.concatMap (
      name: let
        newPath = path + "/${name}";
        type = entries.${name};
      in
        if type == "directory"
        then
          if path == programs-path && name == "_uninstalled"
          then []
          else collectNixFiles newPath
        else if type == "regular" && lib.strings.hasSuffix ".nix" name
        then [newPath]
        else []
    ) (builtins.attrNames entries);

  program-imports = collectNixFiles programs-path;
in {
  imports =
    [
      inputs.sops-nix.homeManagerModules.sops
      inputs.nix-index-database.homeModules.nix-index
    ]
    ++ program-imports;

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

  # Enable Stylix
  stylix = {
    enable = true;
    enableReleaseChecks = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  };
  # Enable fontconfig
  fonts.fontconfig.enable = true;

  # Enable XDG desktop integration
  xdg.enable = true;
  xdg.mime.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
