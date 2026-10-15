_: {
  # ============================================================================
  # Boot Configuration
  # ============================================================================

  boot = {
    # Bootloader
    loader = {
      systemd-boot.enable = true;
      systemd-boot.consoleMode = "max";
      efi.canTouchEfiVariables = true;
    };
  };
}
