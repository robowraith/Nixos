{ config, lib, pkgs, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nvidia.nix
    ../../system/modules/boot.nix
    ../../system/modules/networking.nix
    ../../system/modules/filesystems.nix
    ../../system/modules/users.nix
    ../../system/modules/localization.nix
    ../../system/sops/sops.nix
  ];

  # Machine-specific configuration for desktop PC "reason"
  
  # Scheduler (CachyOS specific)
  services.scx.enable = true;

  # Additional packages specific to this machine
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];
}
