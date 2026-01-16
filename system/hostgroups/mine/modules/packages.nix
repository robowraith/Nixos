{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Core utilities
    dunst
    feh
    flameshot
    ueberzug
    wtfutil

    # Nixos
    alejandra
    statix
    deadnix

    # For secret-tool
    libsecret
    # Terminals
    kitty

    # Sound
    pavucontrol

    #input
    libinput

    # Keyboard firmware
    qmk

    # Logitech mouse
    solaar
    logitech-udev-rules
  ];
}
