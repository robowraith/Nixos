# /dotfiles/programs/sops/sops.nix
{ config, pkgs, ... }:

{
  # sops-nix configuration for home-manager
  sops = {
    enable = true;
    defaultSopsFile = ../../../secrets.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      # Example secret for home-manager
      "hm-secret" = {
        sopsFile = ../../../secrets.yaml;
        key = "hm-secret";
      };
    };
  };
}
