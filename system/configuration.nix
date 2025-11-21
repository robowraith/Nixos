# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot = {
   loader = {
     systemd-boot.enable = true;
     efi.canTouchEfiVariables = true;
     };
     kernelPackages = pkgs.linuxPackages_cachyos-lto;
     
     # Plymouth boot splash (includes LUKS password prompt theming)
     plymouth = {
       enable = true;
       theme = "catppuccin-mocha";
       themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
     };
     
     # Include Plymouth in initrd for LUKS password prompt theming
     initrd.systemd.enable = true;
     
     # Kernel parameters for NVIDIA
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

     # Enable "Silent boot"
     consoleLogLevel = 3;
     initrd.verbose = false;
  };
  services.scx.enable = true; # by default uses scx_rustland scheduler
  
  # NVIDIA Configuration
  services.xserver.videoDrivers = [ "nvidia" ];
  
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false; # Use proprietary driver
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  
  networking.hostName = "reason"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;
  # Static IP configuration
  networking.interfaces.eth0 = {  # adjust interface name as needed
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "192.168.1.111";
        prefixLength = 24;
      }
    ];
  };

  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "192.168.1.3" ];

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "de_DE.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
    useXkbConfig = false; # do not use xkb.options in TTY; keep keyMap as simple console mapping
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound with PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users = {
    users.joachim = {
    uid = 1000;
    isNormalUser = true;
    group = "joachim";
    createHome = true;
    extraGroups = [ "networkmanager" "wheel" "video" "input" "audio" ]; # Enable 'sudo' for the user.
    shell = pkgs.fish;
    };
    groups.joachim = {
      name = "joachim";
      gid = 1000;
    };
  };

  # programs.firefox.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
    file
    fish
    git
    helix
    # Wayland essentials
    wayland
    wayland-utils
    wl-clipboard
    # Basic terminal for emergency access
    kitty
    # NVIDIA utilities
    nvtopPackages.nvidia
  ];

 programs.fish.enable = true; 

 programs.hyprland = {
   enable = true;
   withUWSM = false; # Disable UWSM for now, start Hyprland directly
   xwayland.enable = true;
 };

 # Enable XDG portals for Wayland
 xdg.portal = {
   enable = true;
   extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
   config.common.default = "*";
 };
 
 # Environment variables for NVIDIA + Wayland
 environment.sessionVariables = {
   NIXOS_OZONE_WL = "1";
   GBM_BACKEND = "nvidia-drm";
   __GLX_VENDOR_LIBRARY_NAME = "nvidia";
   LIBVA_DRIVER_NAME = "nvidia";
   WLR_NO_HARDWARE_CURSORS = "1";
 };

 # Enable polkit for privilege escalation
 security.polkit.enable = true;

 services.displayManager.ly = {
   enable = true;
   settings = {
     animation = "matrix";
     clock = "%c";
     tty = 2;  # Run ly on TTY2, leaving TTY1 for emergency getty access
   };
 };
 
 services.displayManager.sessionPackages = [ pkgs.hyprland ];
 
 # Ensure getty runs on TTY1 for emergency shell access
 systemd.services."getty@tty1".enable = true;
 systemd.services."autovt@".enable = true;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];

  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;
  
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheer" ];
  };
  
  nixpkgs.config.allowUnfree = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

}

