{pkgs, ...}: {
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

    # Kernel
    kernelPackages = pkgs.linuxPackages_cachyos-lto;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];

    # Silent boot
    consoleLogLevel = 3;
    initrd.verbose = false;

    # Plymouth boot splash
    plymouth = {
      enable = true;
      # Theme set by stylix
      # theme = "catppuccin-mocha";
      # themePackages = [(pkgs.catppuccin-plymouth.override {variant = "mocha";})];
    };

    # Systemd in initrd for themed LUKS password prompt
    initrd.systemd.enable = true;
  };
}
