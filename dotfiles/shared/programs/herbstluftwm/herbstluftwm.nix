{pkgs, ...}: {
  # Install HerbstluftWM
  home.packages = [pkgs.herbstluftwm];

  # Enable X session for HerbstluftWM
  xsession = {
    enable = true;
    windowManager.command = "${pkgs.herbstluftwm}/bin/herbstluftwm";
  };

  # Write the autostart config to XDG config
  xdg.configFile = {
    "herbstluftwm/autostart" = {
      source = ./autostart;
      executable = true;
      force = true;
    };

    # Copy other configuration files and scripts
    "herbstluftwm/bin" = {
      source = ./bin;
      recursive = true;
    };
    "herbstluftwm/conf.d" = {
      source = ./conf.d;
      recursive = true;
    };
  };
}
