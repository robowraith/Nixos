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
in {
  options.home.cifs = {
    mountPoints = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = map (name: "/home/${username}/${name}") networkShares;
      description = "List of mount points for CIFS shares";
    };
  };

  config = {
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
      config.home.cifs.mountPoints
      (path: mkCifsMount (builtins.baseNameOf path));

    # Create mount point directories
    systemd.tmpfiles.rules = let
      # Get unique parent directories that are not the home directory itself
      parentDirs = lib.unique (map (path: builtins.dirOf path) config.home.cifs.mountPoints);
      filteredParentDirs = builtins.filter (dir: dir != "/home/${username}") parentDirs;
    in
      (map (path: "d ${path} 0755 ${username} ${username} -") filteredParentDirs)
      ++ (map
        (path: "d ${path} 0755 ${username} ${username} -")
        config.home.cifs.mountPoints);
  };
}
