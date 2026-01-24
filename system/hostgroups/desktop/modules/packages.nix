{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # Core utilities

    # # Wayland
    # wayland
    # wayland-utils
    # wl-clipboard

    # Other apps
    signal-desktop
    inputs.zen-browser.packages.${pkgs.system}.default

    # Webcam
    guvcview

    # DRM-Playback
    (chromium.override {enableWideVine = true;})
    (vivaldi.override {enableWidevine = true;})
  ];
}
