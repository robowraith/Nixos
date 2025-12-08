{ pkgs, inputs, hostname, username, stateVersion, ...}:

{
  imports =
    let
      modulesPath = ./modules;
      nixFilesInDir = lib.filterAttrs (name: type:
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
  
  # Better "command not found"
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
  programs.command-not-found.enable = false;
}
