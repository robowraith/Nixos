{ config, lib, pkgs, ... }:

{
  # Desktop environment profile
  # Includes full desktop setup with Hyprland, graphical tools, etc.
  
  # This is already included in shared/default.nix
  # but can be used for other machines that want desktop setup
  
  imports = [ ];
  
  services.xserver.enable = lib.mkDefault true;
}
