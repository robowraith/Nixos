# /system/sops/sops.nix
{ config, pkgs, ... }:

{
  # sops-nix configuration
  sops = {
    enable = true;
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops/age/keys.txt";
    secrets = {
      # Example secret, this will be available as a file at /run/secrets/my-secret
      "my-secret" = {
        sopsFile = ../../secrets.yaml;
        key = "system-secret";
      };
    };
  };
}
