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
      # Allow nixConfig blocks in flakes (e.g. vicinae) to add their own caches
      accept-flake-config = true;
      # devenv.cachix.org and nixpkgs-python.cachix.org are added automatically
      # by the devenv/flake nixConfig (accept-flake-config); listing them here too
      # triggers "already present" warnings. Keep their keys below so the
      # flake-added substituters stay trusted.
      substituters = [
        "https://cache.nixos.org/"
        "https://attic.xuyh0120.win/lantian"
        "https://cache.garnix.io"
        "https://vicinae.cachix.org"
      ];
      trusted-public-keys = [
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
        "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
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
  # TODO: electron-39 is EOL; remove once bitwarden-desktop migrates to a newer electron version
  nixpkgs.config.permittedInsecurePackages = ["electron-39.8.10"];
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
