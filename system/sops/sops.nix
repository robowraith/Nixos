# /system/sops/sops.nix
{ config, pkgs, ... }:

{
  # sops-nix configuration
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops/age/keys.txt";
    secrets = {
      # CIFS credentials for network shares
      "cifs_username" = {
        sopsFile = ../../secrets.yaml;
        key = "system-secrets/cifs_credentials/username";
      };
      "cifs_password" = {
        sopsFile = ../../secrets.yaml;
        key = "system-secrets/cifs_credentials/password";
      };
    };
  };
}
