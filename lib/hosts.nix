{ inputs }:

{
  # Create a NixOS system configuration
  mkHost = { hostname, system ? "x86_64-linux", modules ? [], users ? [] }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs hostname; };
      modules = [
        inputs.sops-nix.nixosModules.sops
        inputs.determinate.nixosModules.default
        ../hosts/${hostname}
        ../hosts/shared
        { networking.hostName = hostname; }
      ] ++ modules;
    };
}
