{ config, lib, pkgs, ... }:

let
  # Helper function to create CIFS mount configurations
  mkCifsMount = name: {
    device = "//192.168.1.3/${name}";
    fsType = "cifs";
    options = [
      "auto"
      "nofail"
      "_netdev"
      "vers=3.0"
      "uid=${toString config.users.users.joachim.uid}"
      "gid=${toString config.users.groups.joachim.gid}"
      "credentials=/etc/cifs-credentials"
    ];
  };

  # List of network share directories
  networkShares = [ "Backup" "Bilder" "Dokumente" "Install" "Musik" "Videos" ];
  
  # Generate mount point paths
  mountPoints = map (name: "/home/joachim/${name}") networkShares;
in
{
  # ============================================================================
  # Filesystems - CIFS Network Shares
  # ============================================================================

  fileSystems = lib.genAttrs
    (map (name: "/home/joachim/${name}") networkShares)
    (path: mkCifsMount (builtins.baseNameOf path));

  # Create mount point directories
  systemd.tmpfiles.rules = map
    (path: "d ${path} 0755 joachim joachim -")
    mountPoints;
}
