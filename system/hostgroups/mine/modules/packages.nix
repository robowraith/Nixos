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
    mcp-nixos # 2.4.3+ in stable uses search.devbox.sh, no unstable needed

    # Nix devenv (unstable for newer version)
    unstable.devenv

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
    yq-go
    kubectx
    kubernetes-helm
    kubernetes-helmPlugins.helm-diff
    cmctl

    # Logitech mouse
    solaar
    logitech-udev-rules

    # Tidal
    high-tide
  ];
}
