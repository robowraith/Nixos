{ config, pkgs, ... }:

{
  # Install HerbstluftWM
  home.packages = [ pkgs.herbstluftwm ];

  # Enable X session for HerbstluftWM
  xsession = {
    enable = true;
    windowManager.command = "${pkgs.herbstluftwm}/bin/herbstluftwm";
    
    # Set locale and keyboard layout
    initExtra = ''
      export LANG=de_DE.UTF-8
      export LC_ALL=de_DE.UTF-8
      setxkbmap de nodeadkeys
    '';
  };

  # Write the autostart config to XDG config
  xdg.configFile."herbstluftwm/autostart" = {
    source = ./autostart;
    executable = true;
    force = true;
  };

  # Copy other configuration files and scripts
  xdg.configFile."herbstluftwm/bin" = {
    source = ./bin;
    recursive = true;
  };
  xdg.configFile."herbstluftwm/conf.d" = {
    source = ./conf.d;
    recursive = true;
  };
}
