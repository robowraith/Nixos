{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Core utilities
    dig
    dysk
    file
    fish
    git
    helix
    killall
    procs
    serpl
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
