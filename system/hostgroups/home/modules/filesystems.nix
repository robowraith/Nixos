{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  # CIFS mount options shared by all shares
  cifsMountOptions = lib.concatStringsSep "," [
    "vers=3.0"
    "uid=${toString config.users.users.${username}.uid}"
    "gid=${toString config.users.groups.${username}.gid}"
    "credentials=${config.sops.templates."cifs-credentials".path}"
  ];

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

    # Mount shares automatically when connecting to the home WiFi "Desire",
    # and unmount them when disconnecting from it.
    # Direct mount/umount calls are used intentionally — no systemd unit files
    # are created, so the activation script never tries to manage these mounts.
    networking.networkmanager.dispatcherScripts = [
      {
        source = pkgs.writeShellScript "cifs-desire-mounts" ''
          INTERFACE="$1"
          ACTION="$2"
          # CONNECTION_ID is provided by NetworkManager and matches the WiFi SSID
          # for auto-created connections.
          case "$ACTION" in
            up)
              if [ "$CONNECTION_ID" = "Desire" ]; then
                ${lib.concatMapStrings (path: ''
                  ${pkgs.cifs-utils}/bin/mount.cifs \
                    "//192.168.1.3/${builtins.baseNameOf path}" \
                    "${path}" \
                    -o "${cifsMountOptions}" 2>/dev/null || true
                '') config.home.cifs.mountPoints}
              fi
              ;;
            pre-down)
              if [ "$CONNECTION_ID" = "Desire" ]; then
                ${lib.concatMapStrings (path: ''
                  ${pkgs.util-linux}/bin/umount "${path}" 2>/dev/null || true
                '') config.home.cifs.mountPoints}
              fi
              ;;
          esac
        '';
        type = "basic";
      }
    ];
  };
}
