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

  # Single definition: nixpkgs.config merges by recursiveUpdate, so a second list elsewhere replaces this one.
  nixpkgs.config.permittedInsecurePackages = [
    # TODO: electron-39 is EOL; remove once bitwarden-desktop migrates to a newer electron version
    "electron-39.8.10"
    # TODO: electron-42 is EOL; jhoss's obsidian is pinned to it because electron 43 breaks its
    # renderer (dotfiles/users/jhoss/programs/obsidian). Remove together with that pin.
    "electron-42.11.18"
  ];
}
