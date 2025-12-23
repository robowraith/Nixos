_: {
  # ============================================================================
  # Display Manager
  # ============================================================================

  services = {
    displayManager = {
      ly = {
        enable = true;
        settings = {
          animation = "matrix";
          clock = "%c";
          tty = 1;
        };
      };
    };

    xserver = {
      enable = true;
      windowManager.herbstluftwm.enable = true;
      xkb = {
        layout = "de";
        variant = "nodeadkeys";
      };
    };

    libinput.enable = true;
  };
}
