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
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Webcam
    guvcview

    # DRM-Playback
    (chromium.override {enableWideVine = true;})
    (vivaldi.override {enableWidevine = true;})

    # Fonts
    nerd-fonts.fira-code
  ];

  programs.dconf.enable = true;

  # TODO: electron-39 is EOL; remove once bitwarden-desktop migrates to a newer electron version
  nixpkgs.config.permittedInsecurePackages = ["electron-39.8.10"];
}
