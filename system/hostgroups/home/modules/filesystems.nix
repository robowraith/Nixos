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

  # Shared mount/umount logic, invoked both by the NetworkManager dispatcher
  # (roaming) and by a boot-time service (see below). $1 is the number of
  # reachability probes to make before giving up.
  #
  # Direct mount/umount calls are used intentionally — no `fileSystems` entries
  # and therefore no generated .mount units, so activation never tries to manage
  # these mounts.
  mountScript = pkgs.writeShellScript "cifs-home-mounts" ''
    set -u
    ATTEMPTS="''${1:-2}"

    # Serialize concurrent invocations: the dispatcher fires once per interface
    # (eth + wifi) and may overlap with the boot-time service.
    LOCK=/run/cifs-home-mounts.lock
    exec 9>"$LOCK"
    ${pkgs.util-linux}/bin/flock -w 60 9 || exit 0

    CREDS="${config.sops.templates."cifs-credentials".path}"
    SMBCLIENT="${pkgs.samba}/bin/smbclient"
    # cifs-utils is multi-output since nixpkgs 26.05: the default `out` is empty
    # and the binaries go to `bin`, under sbin/ (configureFlags ROOTSBINDIR).
    MOUNT_CIFS="${pkgs.cifs-utils.bin}/sbin/mount.cifs"
    UMOUNT="${pkgs.util-linux}/bin/umount"
    MOUNTPOINT="${pkgs.util-linux}/bin/mountpoint"

    # True iff the server at ${smbServer} is reachable AND advertises the
    # expected share — guards against foreign subnets reusing the same IP.
    at_home() {
      for _ in $(${pkgs.coreutils}/bin/seq 1 "$ATTEMPTS"); do
        "$SMBCLIENT" -L "//${smbServer}" -A "$CREDS" -t 2 -g 2>/dev/null \
          | grep -q "^Disk|${identityShare}|" && return 0
        sleep 2
      done
      return 1
    }

    if at_home; then
      ${lib.concatMapStrings (path: ''
        if ! "$MOUNTPOINT" -q "${path}"; then
          # Failures are logged rather than discarded: a silent mount failure
          # is indistinguishable from being away from home.
          if "$MOUNT_CIFS" "//${smbServer}/${builtins.baseNameOf path}" "${path}" \
            -o "${cifsMountOptions}"; then
            echo "mounted ${path}"
          else
            echo "failed to mount ${path}" >&2
          fi
        fi
      '')
      config.home.cifs.mountPoints}
    else
      echo "SMB server ${smbServer} not reachable after $ATTEMPTS probes; unmounting shares" >&2
      ${lib.concatMapStrings (path: ''
        if "$MOUNTPOINT" -q "${path}"; then
          "$UMOUNT" "${path}" 2>/dev/null || true
        fi
      '')
      config.home.cifs.mountPoints}
    fi
  '';
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

    # Mount at boot, ordered after the network is genuinely routable.
    #
    # The dispatcher alone is not enough: it fires on link-up, which at boot can
    # precede network-online.target by several seconds. The probe then burns its
    # whole budget before anything is reachable, concludes we are away from home,
    # and — with no retry and no further NM event — leaves the shares unmounted
    # until the next connection change.
    systemd.services.cifs-home-mounts = {
      description = "Mount home CIFS shares";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      # Keep activation out of these mounts, as with the dispatcher: a rebuild
      # should not tear down and re-probe live shares.
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # More patient than the dispatcher — nothing else will retry at boot.
        ExecStart = "${mountScript} 10";
      };
    };

    # Re-evaluate on connection changes too, so roaming between home and
    # elsewhere mounts and unmounts the shares. Kept short: when away from home
    # every probe is dead time on every network event.
    networking.networkmanager.dispatcherScripts = [
      {
        source = pkgs.writeShellScript "cifs-home-mounts-dispatch" ''
          set -u
          case "$2" in
            up|down|pre-down|dhcp4-change|dhcp6-change|connectivity-change) ;;
            *) exit 0 ;;
          esac
          exec ${mountScript} 3
        '';
        type = "basic";
      }
    ];
  };
}
