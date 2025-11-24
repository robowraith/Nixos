{
  description = "Multi-machine, multi-user NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
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

  outputs = { self, nixpkgs, chaotic, determinate, home-manager, stylix, sops-nix, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      
      # Import our library functions
      lib = import ./lib { inherit inputs; };
      
      # Define all hosts
      hosts = {
        reason = {
          hostname = "reason";
          modules = [
            chaotic.nixosModules.default
          ];
        };
        # Add more hosts here as needed
        # laptop = {
        #   hostname = "laptop";
        #   modules = [ ./profiles/minimal.nix ];
        # };
      };
      
      # Define all users and which hosts they use
      users = {
        joachim = {
          username = "joachim";
          hosts = [ "reason" ]; # Can add more: [ "reason" "laptop" ]
        };
        # Add more users here
        # work = {
        #   username = "work-user";
        #   hosts = [ "laptop" ];
        # };
      };
      
      # Generate user@host combinations
      mkUserHostConfigs = userName:
        let
          userConfig = users.${userName};
        in
        builtins.map (host: {
          name = "${userName}@${host}";
          value = lib.users.mkUser {
            inherit (userConfig) username;
            inherit host;
          };
        }) userConfig.hosts;
      
    in {
      # NixOS system configurations for all hosts
      nixosConfigurations = builtins.mapAttrs 
        (name: config: lib.hosts.mkHost config) 
        hosts;

      # Home Manager configurations for all user@host combinations
      homeConfigurations = builtins.listToAttrs (
        builtins.concatLists (
          builtins.map mkUserHostConfigs (builtins.attrNames users)
        )
      );
      
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
          echo "NixOS multi-machine configuration development environment"
          echo "Available tools: nixpkgs-fmt, nil, age, sops"
          echo ""
          echo "Hosts: ${builtins.concatStringsSep ", " (builtins.attrNames hosts)}"
          echo "Users: ${builtins.concatStringsSep ", " (builtins.attrNames users)}"
        '';
      };
      
      # Formatter for 'nix fmt'
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
