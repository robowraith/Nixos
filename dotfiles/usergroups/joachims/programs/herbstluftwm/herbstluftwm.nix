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
  # Overwritten in user specific configs
  #   "herbstluftwm/autostart" = {
  #     source = ./autostart;
  #     executable = true;
  #     force = true;
  #   };

    # Copy other configuration files and scripts
    "herbstluftwm/bin" = {
      source = ./bin;
      recursive = true;
    };
    "herbstluftwm/conf.d/keybindings.fish".source = ./conf.d/keybindings.fish;
    "herbstluftwm/conf.d/rules.fish".source = ./conf.d/rules.fish;
    "herbstluftwm/conf.d/tags.fish".source = ./conf.d/tags.fish;
    "herbstluftwm/conf.d/theme.fish".source = ./conf.d/theme.fish;
  };
}
