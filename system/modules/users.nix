{ config, lib, pkgs, ... }:

{
  # ============================================================================
  # Users
  # ============================================================================

  users = {
    users.joachim = {
      uid = 1000;
      isNormalUser = true;
      group = "joachim";
      createHome = true;
      extraGroups = [ "networkmanager" "wheel" "video" "input" "audio" ];
      shell = pkgs.fish;
    };

    groups.joachim = {
      name = "joachim";
      gid = 1000;
    };
  };
}
