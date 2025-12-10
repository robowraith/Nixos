{
  config,
  lib,
  username,
  ...
}: let
  # Helper function to create CIFS mount configurations
  mkCifsMount = name: {
    device = "//192.168.1.3/${name}";
    fsType = "cifs";
    options = [
      "auto"
      "nofail"
      "_netdev"
      "vers=3.0"
      "uid=${toString config.users.users.${username}.uid}"
      "gid=${toString config.users.groups.${username}.gid}"
      "credentials=${config.sops.templates."cifs-credentials".path}"
    ];
  };

  # List of network share directories
  networkShares = ["Backup" "Bilder" "Dokumente" "Install" "Musik" "Videos"];

  # Generate mount point paths
  mountPoints = map (name: "/home/${username}/${name}") networkShares;
in {
  # ============================================================================
  # Filesystems - CIFS Network Shares
  # ============================================================================

  sops = {
    secrets = {
      "home_cifs_credentials/username" = {};
      "home_cifs_credentials/password" = {};
    };
    templates."cifs-credentials".content = ''
      username=${config.sops.placeholder."home_cifs_credentials/username"}
      password=${config.sops.placeholder."home_cifs_credentials/password"}
    '';
  };

  fileSystems =
    lib.genAttrs
    (map (name: "/home/${username}/${name}") networkShares)
    (path: mkCifsMount (builtins.baseNameOf path));

  # Create mount point directories
  systemd.tmpfiles.rules =
    map
    (path: "d ${path} 0755 ${username} ${username} -")
    mountPoints;
}
