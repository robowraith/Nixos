{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ============================================================================
  # System Configuration
  # ============================================================================

  system.stateVersion = "25.05";

  # ============================================================================
  # Nix Settings
  # ============================================================================

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheer" ];
  };

  nixpkgs.config.allowUnfree = true;

  # ============================================================================
  # Boot Configuration
  # ============================================================================

  boot = {
    # Bootloader
    loader = {
      systemd-boot.enable = true;
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
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];

    # Silent boot
    consoleLogLevel = 3;
    initrd.verbose = false;

    # Plymouth boot splash
    plymouth = {
      enable = true;
      theme = "catppuccin-mocha";
      themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
    };

    # Systemd in initrd for themed LUKS password prompt
    initrd.systemd.enable = true;
  };

  # ============================================================================
  # Scheduler
  # ============================================================================

  services.scx.enable = true;

  # ============================================================================
  # Hardware Configuration
  # ============================================================================

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    hostName = "reason";
    networkmanager.enable = true;

    # Static IP configuration
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "192.168.1.111";
        prefixLength = 24;
      }];
    };

    defaultGateway = "192.168.1.1";
    nameservers = [ "192.168.1.3" ];

    # Firewall
    firewall.allowedTCPPorts = [ 22 ];
  };

  # ============================================================================
  # Localization
  # ============================================================================

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "de_DE.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
    useXkbConfig = false;
  };

  # ============================================================================
  # Audio
  # ============================================================================

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ============================================================================
  # Users
  # ============================================================================

  users = {
    users.joachim = {
      uid = 1000;
      isNormalUser = true;
      group = "joachim";
      createHome = true;
      extraGroups = [ "networkmanager" "wheel" "video" "input" "audio" ];
      shell = pkgs.fish;
    };

    groups.joachim = {
      name = "joachim";
      gid = 1000;
    };
  };

  # ============================================================================
  # System Packages
  # ============================================================================

  environment.systemPackages = with pkgs; [
    # Core utilities
    file
    fish
    git
    helix

    # Wayland
    wayland
    wayland-utils
    wl-clipboard

    # Terminal
    kitty

    # NVIDIA utilities
    nvtopPackages.nvidia
  ];

  # Environment variables for NVIDIA + Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # ============================================================================
  # Programs
  # ============================================================================

  programs.fish.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = false;
    xwayland.enable = true;
  };

  # ============================================================================
  # XDG & Portals
  # ============================================================================

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # ============================================================================
  # Security
  # ============================================================================

  security.polkit.enable = true;

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
    sessionPackages = [ pkgs.hyprland ];
  };

  # Emergency shell access on TTY1
  systemd.services."getty@tty1".enable = true;
  systemd.services."autovt@".enable = true;

  # ============================================================================
  # Services
  # ============================================================================

  services.openssh.enable = true;

}
