{ inputs }:

{
  hosts = import ./hosts.nix { inherit inputs; };
  users = import ./users.nix { inherit inputs; };
}
