_: {
  # ============================================================================
  # Display Manager
  # ============================================================================

  services.displayManager = {
    ly = {
      enable = true;
      settings = {
        animation = "matrix";
        clock = "%c";
        tty = 1;
      };
    };
  };

  services.xserver = {
    enable = true;
    windowManager.herbstluftwm.enable = true;
    xkb = {
      layout = "de";
      variant = "nodeadkeys";
    };
  };

  services.libinput.enable = true;
}
