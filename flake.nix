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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, chaotic, home-manager, stylix, sops-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      
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
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            stylix.homeModules.stylix
            sops-nix.homeManagerModules.sops
            ./dotfiles/home.nix
            {
              home = {
                inherit (config) username homeDirectory;
                stateVersion = "25.05";
              };
            }
          ];
        };
    in {
      # NixOS system configuration
      nixosConfigurations.reason = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          sops-nix.nixosModules.sops
          ./system/configuration.nix
          chaotic.nixosModules.default
        ];
      };

      # Home Manager configurations
      homeConfigurations = builtins.mapAttrs mkHomeConfig userConfigs;
      
      # Development shell
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixpkgs-fmt
          nil # Nix LSP
          age
          sops
          git
        ];
        
        shellHook = ''
          echo "NixOS configuration development environment"
          echo "Available tools: nixpkgs-fmt, nil, age, sops"
        '';
      };
      
      # Formatter for 'nix fmt'
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
