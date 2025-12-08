{...}: {
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
    layout = "de";
    xkbVariant = "nodeadkeys";
  };
}
