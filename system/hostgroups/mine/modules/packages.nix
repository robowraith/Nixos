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
    unstable.mcp-nixos # stable 1.0.3 uses dead nixhub.io Remix endpoint; unstable uses search.devbox.sh

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
