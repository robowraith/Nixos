{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Core utilities
    dunst
    feh
    flameshot
    numlockx
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

    # Kubernetes
    kubectl
    kubectx
    
    # Logitech mouse
    solaar
    logitech-udev-rules
  ];
}
