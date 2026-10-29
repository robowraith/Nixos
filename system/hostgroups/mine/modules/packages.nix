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
    unstable.mcp-nixos # stable 2.4.3 unbuildable: its fastmcp 3.2.3 fails tests with anyio 4.15 (NixOS/nixpkgs#580398); back to stable once #580411 lands

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
