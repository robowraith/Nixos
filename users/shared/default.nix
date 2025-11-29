{ config, pkgs, lib, ... }:

let
  programsPath = ./programs;
  programDirs = builtins.attrNames (builtins.readDir programsPath);
  # Filter out non-directories and the _uninstalled directory
  filteredProgramDirs = builtins.filter (dir:
    let
      path = programsPath + "/${dir}";
      isDirResult = builtins.tryEval (builtins.readDir path);
    in
      isDirResult.success && (dir != "_uninstalled")
  ) programDirs;
in
{
  imports =
    lib.flatten (builtins.map (dir:
      let
        programPath = programsPath + "/${dir}";
        files = builtins.attrNames (builtins.readDir programPath);
        nixFiles = builtins.filter (file: lib.strings.hasSuffix ".nix" file) files;
      in
        map (file: programPath + "/${file}") nixFiles
    ) filteredProgramDirs);

  home.packages = with pkgs;
    let
      # Filter program names that exist as packages in pkgs
      existingPackages = builtins.filter (name: builtins.hasAttr name pkgs) filteredProgramDirs;
    in
      # Map names to actual packages
      map (name: builtins.getAttr name pkgs) existingPackages ++ [ pkgs.nix-prefetch-github ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  };
  # Enable fontconfig
  fonts.fontconfig.enable = true;
  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Enable XDG desktop integration
  xdg.enable = true;
  xdg.mime.enable = true;
}
