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

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    sops-nix,
    nix-cachyos-kernel,
    stylix,
    nix-index-database,
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
        inherit specialArgs;
        modules = [
          {nixpkgs.hostPlatform = platform;}
          # Core System Configuration
          ./system/hosts/${hostname}
          ./system/shared

          # Modules
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix
          nix-index-database.nixosModules.nix-index
          home-manager.nixosModules.home-manager

          # Overlays
          {
            nixpkgs.overlays = [
              nix-cachyos-kernel.overlays.pinned
              (_final: prev: {
                herbstluftwm = prev.herbstluftwm.overrideAttrs (oldAttrs: {
                  postPatch =
                    (oldAttrs.postPatch or "")
                    + ''
                      sed -i '15i #include <cstdint>' src/xconnection.cpp
                    '';
                });
                freac = prev.freac.overrideAttrs (oldAttrs: {
                  nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [prev.makeWrapper];
                  buildInputs =
                    (oldAttrs.buildInputs or [])
                    ++ [
                      prev.lame
                      prev.flac
                      prev.faac
                      prev.faad2
                      prev.libvorbis
                      prev.libopus
                      prev.mpg123
                    ];
                  postFixup =
                    (oldAttrs.postFixup or "")
                    + ''
                      wrapProgram $out/bin/freac \
                        --prefix LD_LIBRARY_PATH : "${prev.lib.makeLibraryPath [
                        prev.lame
                        prev.flac
                        prev.faac
                        prev.faad2
                        prev.libvorbis
                        prev.libopus
                        prev.mpg123
                      ]}"
                    '';
                });
              })
            ];
          }

          # Home Manager Configuration
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = ".backup";
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
      # stella = mkHost {
      #   hostname = "stella";
      #   username = "iris";
      # };
      # My Work Notebook
      deepthought = mkHost {
        hostname = "deepthought";
        username = "jhoss";
      };
      # wintermute = mkHost {
      #   hostname = "wintermute";
      #   username = "dixie";
      # };
      # neuromancer = mkHost {
      #   hostname = "neuromancer";
      #   username = "case";
      # };

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
