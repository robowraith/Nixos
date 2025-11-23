{ inputs }:

let
  system = "x86_64-linux";
in
{
  # Create a Home Manager user configuration
  mkUser = { username, host ? null, extraModules ? [] }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      extraSpecialArgs = { inherit inputs username host; };
      modules = [
        inputs.stylix.homeModules.stylix
        inputs.sops-nix.homeManagerModules.sops
        ../users/shared
        ../users/${username}
        {
          home = {
            inherit username;
            homeDirectory = "/home/${username}";
            stateVersion = "25.05";
          };
        }
      ] ++ extraModules 
        ++ (if host != null && builtins.pathExists ../users/${username}/${host}.nix
            then [ ../users/${username}/${host}.nix ]
            else []);
    };
}
