{ config, lib, pkgs, ...}:

{
  environment.systemPackages = with pkgs; [
    # Core utilities
    feh
    xrandr

    # # Wayland
    # wayland
    # wayland-utils
    # wl-clipboard

    # NVIDIA utilities
    nvtopPackages.nvidia
  ];
}
