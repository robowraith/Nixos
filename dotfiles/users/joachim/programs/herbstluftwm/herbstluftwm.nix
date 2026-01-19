_: {
  # Write the autostart config to XDG config
  xdg.configFile = {
    "herbstluftwm/autostart" = {
      source = ./autostart;
      executable = true;
      force = true;
    };
  };
}
