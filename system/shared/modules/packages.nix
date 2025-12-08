{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Core utilities
    file
    fish
    git
    helix

    # Secrets management
    age
    sops
  ];

  programs = {
    fish.enable = true;
    dconf.enable = true;
  };
}
