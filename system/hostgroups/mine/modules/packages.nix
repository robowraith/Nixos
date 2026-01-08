{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Core utilities
    dunst
    feh
    flameshot
    ueberzug
    wtfutil

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
