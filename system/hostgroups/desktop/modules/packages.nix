{pkgs, inputs, ...}: {
  environment.systemPackages = with pkgs; [
    # Core utilities

    # # Wayland
    # wayland
    # wayland-utils
    # wl-clipboard

    # Other apps
    signal-desktop
    inputs.zen-browser.packages.${pkgs.system}.default
  ];
}
