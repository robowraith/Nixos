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
      substituters = ["https://cache.nixos.org/" "https://attic.xuyh0120.win/lantian" "https://cache.garnix.io"];
      trusted-public-keys = ["lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="];
    };
    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "daily";
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
