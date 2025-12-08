{
  description = "My take on a dendritic, DRY, hierarchical multi-machine, multi-user NixOS and Home Manager configuration.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    sops-nix,
    chaotic,
    stylix,
    pre-commit-hooks,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # Helper function to create a host configuration
    mkHost = {
      hostname,
      username,
      platform ? "x86_64-linux",
      stateVersion ? "25.11",
    }: let
      specialArgs = {
        inherit inputs hostname username platform stateVersion;
      };
    in
      nixpkgs.lib.nixosSystem {
        system = platform;
        inherit specialArgs;
        modules = [
          # Core System Configuration
          ./system/hosts/${hostname}
          ./system/shared

          # Modules
          sops-nix.nixosModules.sops
          chaotic.nixosModules.default
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager

          # Home Manager Configuration
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              users.${username} = import ./dotfiles/users/${username};
            };
          }
        ];
      };
  in {
    nixosConfigurations = {
      # My Desktop
      reason = mkHost {
        hostname = "reason";
        username = "joachim";
      };
      # Her Notebook
      stella = mkHost {
        hostname = "stella";
        username = "iris";
      };
      # My Work Notebook
      deepthought = mkHost {
        hostname = "deepthought";
        username = "jhoss";
      };
      wintermute = mkHost {
        hostname = "wintermute";
        username = "dixie";
      };
      neuromancer = mkHost {
        hostname = "neuromancer";
        username = "case";
      };

      # You can add other hosts here using the helper
      # "42he-Infinitybook" = mkHost { hostname = "42he-Infinitybook"; username = "joachim"; };
    };

    # Pre-commit checks
    checks.${system}.pre-commit-check = pre-commit-hooks.lib.${system}.run {
      src = ./.;
      hooks = {
        alejandra.enable = true;
        statix.enable = true;
        deadnix.enable = true;
      };
    };

    # Devshell for bootstrapping and maintenance
    devShells.${system}.default = pkgs.mkShell {
      inherit (self.checks.${system}.pre-commit-check) shellHook;
      buildInputs = with pkgs; [
        git
        alejandra
        statix
        deadnix
        sops
        ssh-to-age
        home-manager.packages.${system}.home-manager
      ];
    };
  };
}
