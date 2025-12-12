{
  pkgs,
  stateVersion,
  lib,
  ...
}: {
  imports = let
    modulesPath = ./modules;
    nixFilesInDir = lib.filterAttrs (
      name: type:
        type == "regular" && lib.hasSuffix ".nix" name
    ) (builtins.readDir modulesPath);
  in
    lib.mapAttrsToList (name: _: modulesPath + "/${name}") nixFilesInDir;

  # System State Version
  system.stateVersion = stateVersion;

  # Nix Configuration
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
    };
    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # Enable Stylix
  stylix = {
    enable = true;
    enableReleaseChecks = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  };

  # Better "command not found"
  programs = {
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
    command-not-found.enable = false;
  };
}
