{
  description = "Home Manager configuration";

  inputs = {
    # Use nixpkgs-unstable for the latest packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      # This ensures home-manager uses the same nixpkgs version
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, stylix, ... }:
    let
      # Define user configurations for different devices
      userConfigs = {
        # Primary user configuration
        joachim = {
          username = "joachim";
          homeDirectory = "/home/joachim";
        };

        # Add more configurations as needed
        # work = {
        #   username = "<work-username>";
        #   homeDirectory = "/home/<work-username>";
        # };
      };

      mkHomeConfig = name: config:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            stylix.homeModules.stylix
            ./home.nix
            {
              home = {
                inherit (config) username homeDirectory;
                stateVersion = "24.11";
              };

              # Protect Omarchy-managed directories
              # home.file.".config/omarchy".enable = false;
              # home.file.".config/hypr".enable = false;
              # home.file.".config/alacritty".enable = false;
              # home.file.".config/btop/themes".enable = false;
            }
          ];
        };
    in {
      homeConfigurations = builtins.mapAttrs mkHomeConfig userConfigs;
    };
}
