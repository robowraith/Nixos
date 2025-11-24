{ config, pkgs, lib, username, host, ... }:

{
  # User-specific configuration for joachim
  
  # Import host-specific config if it exists
  # (e.g., reason.nix for desktop-specific settings)
  
  # User-specific packages not in shared config
  home.packages = with pkgs; [
    # Add any user-specific packages here
  ];

  # User-specific Git configuration
  programs.git = {
    settings = {
      user = {
        name = "Joachim Hoss";
        email = "robowraith@gmail.com";
      };
    };
  };
}
