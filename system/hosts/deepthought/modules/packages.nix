{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Core utilities
    feh
    xrandr

    slack
    unstable.openspec
  ];
}
