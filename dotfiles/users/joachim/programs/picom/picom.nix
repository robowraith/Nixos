{pkgs, ...}: {
  # Install the picom package for the user
  home.packages = [pkgs.picom];

  # Write a standard picom config to the user's XDG config directory
  xdg.configFile."picom/picom.conf".source = ./picom.conf;
}
