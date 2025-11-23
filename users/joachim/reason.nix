{ config, pkgs, lib, username, host, ... }:

{
  # Desktop-specific configuration for joachim on the "reason" machine
  
  # Desktop-specific environment variables or settings
  home.sessionVariables = {
    # Add any desktop-specific variables
  };
  
  # Desktop-specific packages
  home.packages = with pkgs; [
    # Add desktop-specific packages
  ];
}
