{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Core utilities
    dysk
    file
    fish
    git
    helix
    killall
    procs
    tldr
    wget

    # Fonts
    nerd-fonts.fira-code

    # Secrets management
    age
    sops
  ];

  programs = {
    fish.enable = true;
    dconf.enable = true;
  };
}
