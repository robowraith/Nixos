{
  config,
  lib,
  ...
}: let
  inherit (config.boot.kernelPackages) nvidiaPackages;
  # 26.05's 595.71.05 open module calls strncpy, which zen 7.2.11 no longer provides. Until the channel ships a
  # newer driver, build NVIDIA's 595.104.02 (hashes from nixpkgs-unstable) against our kernel. Falls back to the
  # channel's driver by itself once that is at least as new; delete the override then.
  nvidiaPackage =
    if lib.versionOlder nvidiaPackages.stable.version "595.104.02"
    then
      nvidiaPackages.mkDriver {
        version = "595.104.02";
        sha256_64bit = "sha256-5CHCAuTHn1jDx/MWG75xRU67PYiTb4ggWg4yfNBMWco=";
        sha256_aarch64 = "sha256-PafStmwNMufeDp3VtpTGGCoW+53Gor/mieO1m1pI7gI=";
        openSha256 = "sha256-FWk5ra2yjz8VAxAA8GXrSoeBj/XC1BKvsKsBKR09joE=";
        settingsSha256 = "sha256-4Kxro6tvI5aX4nu2RspgyBsW+Jq3/VYjSAS5UGdzTCU=";
        persistencedSha256 = "sha256-JsMLPqJuZwAtHngsQODMsmgO7F2tVkQ2arc7fYa2bwo=";
      }
    else nvidiaPackages.stable;
in {
  # ============================================================================
  # Hardware Configuration - Graphics & NVIDIA
  # ============================================================================

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = nvidiaPackage;
  };

  # Environment variables for NVIDIA + Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
