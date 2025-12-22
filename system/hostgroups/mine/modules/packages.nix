{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Core utilities
    dunst
    feh
    flameshot
    ueberzug

    # Terminals
    kitty

    # Sound
    pavucontrol

    #input
    libinput
  ];
}
