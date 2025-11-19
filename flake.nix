{
  description = "My NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, chaotic, home-manager, stylix, ... }:
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
            ./dotfiles/home.nix
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
      # NixOS system configuration
      nixosConfigurations.reason = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./system/configuration.nix
          chaotic.nixosModules.default
        ];
      };

      # Home Manager configurations
      homeConfigurations = builtins.mapAttrs mkHomeConfig userConfigs;
    };
}
