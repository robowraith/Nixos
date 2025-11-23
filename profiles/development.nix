{ config, lib, pkgs, ... }:

{
  # Development profile
  # Common development tools and environments
  
  environment.systemPackages = with pkgs; [
    # Version control
    git
    gh
    
    # Build tools
    gnumake
    cmake
    
    # Languages
    python3
    nodejs
    go
    rustc
    cargo
  ];
}
