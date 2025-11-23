# /system/sops/sops.nix
{ config, pkgs, hostname, ... }:

{
  # sops-nix configuration
  sops = {
    defaultSopsFile = ../../secrets/${hostname}.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops/age/keys.txt";
    
    secrets = {
      # CIFS credentials for network shares
      "cifs_username" = {
        sopsFile = ../../secrets/${hostname}.yaml;
        key = "system-secrets/cifs_credentials/username";
      };
      "cifs_password" = {
        sopsFile = ../../secrets/${hostname}.yaml;
        key = "system-secrets/cifs_credentials/password";
      };
    };

    # Generate /etc/cifs-credentials file from secrets
    templates."cifs-credentials" = {
      path = "/etc/cifs-credentials";
      content = ''
        username=${config.sops.placeholder.cifs_username}
        password=${config.sops.placeholder.cifs_password}
      '';
      mode = "0600";
      owner = "root";
      group = "root";
    };
  };
}
