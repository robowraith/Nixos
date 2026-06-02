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

  # Home SMB server and a known share used as an identity probe so we don't
  # accidentally mount from a foreign subnet that happens to reuse this IP.
  smbServer = "192.168.1.3";
  identityShare = "Dokumente";
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

    # smbclient for the identity probe (and ad-hoc debugging).
    environment.systemPackages = [pkgs.samba];

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

    # Mount shares whenever the home SMB server is actually reachable, on any
    # interface — robust to ethernet+WiFi race orderings and to foreign subnets
    # that happen to reuse 192.168.1.3 (the share-name probe guards against it).
    # Direct mount/umount calls are used intentionally — no systemd unit files
    # are created, so the activation script never tries to manage these mounts.
    networking.networkmanager.dispatcherScripts = [
      {
        source = pkgs.writeShellScript "cifs-home-mounts" ''
          set -u
          ACTION="$2"

          case "$ACTION" in
            up|down|pre-down|dhcp4-change|dhcp6-change|connectivity-change) ;;
            *) exit 0 ;;
          esac

          # Serialize concurrent dispatcher invocations (eth + wifi fire together).
          LOCK=/run/cifs-home-mounts.lock
          exec 9>"$LOCK"
          ${pkgs.util-linux}/bin/flock -w 10 9 || exit 0

          CREDS="${config.sops.templates."cifs-credentials".path}"
          SMBCLIENT="${pkgs.samba}/bin/smbclient"
          MOUNT_CIFS="${pkgs.cifs-utils}/bin/mount.cifs"
          UMOUNT="${pkgs.util-linux}/bin/umount"
          MOUNTPOINT="${pkgs.util-linux}/bin/mountpoint"

          # True iff the server at ${smbServer} is reachable AND advertises the
          # expected share — guards against foreign subnets reusing the same IP.
          at_home() {
            for _ in 1 2; do
              "$SMBCLIENT" -L "//${smbServer}" -A "$CREDS" -t 2 -g 2>/dev/null \
                | grep -q "^Disk|${identityShare}|" && return 0
              sleep 1
            done
            return 1
          }

          if at_home; then
            ${lib.concatMapStrings (path: ''
              if ! "$MOUNTPOINT" -q "${path}"; then
                "$MOUNT_CIFS" "//${smbServer}/${builtins.baseNameOf path}" "${path}" \
                  -o "${cifsMountOptions}" 2>/dev/null || true
              fi
            '')
            config.home.cifs.mountPoints}
          else
            ${lib.concatMapStrings (path: ''
              if "$MOUNTPOINT" -q "${path}"; then
                "$UMOUNT" "${path}" 2>/dev/null || true
              fi
            '')
            config.home.cifs.mountPoints}
          fi
        '';
        type = "basic";
      }
    ];
  };
}
