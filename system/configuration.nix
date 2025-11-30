{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./sops/sops.nix
    ./modules/boot.nix
    ./modules/networking.nix
    ./modules/nvidia.nix
    ./modules/filesystems.nix
    ./modules/users.nix
    ./modules/localization.nix
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
    trusted-users = [ "root" "@wheel" ];
    
    # Chaotic Nyx binary cache
    substituters = [
      "https://cache.nixos.org"
      "https://nyx.chaotic.cx"
    ];
    trusted-public-keys = [
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    ];
  };
  
  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;

  # ============================================================================
  # Scheduler
  # ============================================================================

  services.scx.enable = true;

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
  # System Packages
  # ============================================================================

  environment.systemPackages = with pkgs; [
    # Core utilities
    feh
    file
    fish
    git
    helix
    xrandr

    # Secrets management
    age
    sops

    # # Wayland
    # wayland
    # wayland-utils
    # wl-clipboard

    # Terminal
    kitty

    # NVIDIA utilities
    nvtopPackages.nvidia
  ];

  # ============================================================================
  # Programs
  # ============================================================================

  programs.fish.enable = true;

  # ============================================================================
  # XDG & Portals
  # ============================================================================

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common.default = [ "gtk" ];
    };
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
  };

  # Emergency shell access on TTY1
  systemd.services."getty@tty1".enable = true;
  systemd.services."autovt@".enable = true;

  # ============================================================================
  # Services
  # ============================================================================

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

}
