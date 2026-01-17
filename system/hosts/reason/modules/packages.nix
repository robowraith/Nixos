{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Core utilities
    feh
    xrandr

    # Audio
    freac
    lame

    # # Wayland
    # wayland
    # wayland-utils
    # wl-clipboard

    # NVIDIA utilities
    nvtopPackages.nvidia
  ];
}
