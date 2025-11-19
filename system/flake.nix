{
  description = "My NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };
  outputs = inputs@{ self, nixpkgs, chaotic, ... }: {
   nixosConfigurations.reason = nixpkgs.lib.nixosSystem {
      system = "X86_64-linux";
      modules = [
        ./configuration.nix
        chaotic.nixosModules.default
      ];
    };
  };
}
