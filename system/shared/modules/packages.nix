{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Core utilities
    dig
    dysk
    file
    fish
    git
    helix
    jq
    killall
    procs
    serpl
    tldr
    wget

    # Secrets management
    age
    sops
  ];

  programs.fish.enable = true;
}
