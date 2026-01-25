_: {
  # Write the autostart config to XDG config
  xdg.configFile = {
    "herbstluftwm/autostart" = {
      source = ./autostart;
      executable = true;
      force = true;
    };
    "herbstluftwm/conf.d/screen_setup.fish" = {
      source = ./conf.d/screen_setup.fish;
    };
    "herbstluftwm/bin/setup_main_workspace.fish" = {
      source = ./bin/setup_main_workspace.fish;
    };
  };
}
