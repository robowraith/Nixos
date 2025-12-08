{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Core utilities
    feh

    # # Wayland
    # wayland
    # wayland-utils
    # wl-clipboard

    # Terminal
    kitty
  ];
}
