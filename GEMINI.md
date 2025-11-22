# The project

This is the Nixos-Configuration of a machine running Nixos-unstable
and using Home Manager to manage user applications and configuration

## Structure

The system configuration is under system/, the Home Manager configuration
under dotfiles/. All is tied together in a Flake at ./flake.nix.
The base configuration files (home.nix and configuration.nix) should contain
only general configuration options specific options shall be organized in
their own subfolders and files.
Example: The configuration for Helix is in dotfiles/programs/helix/helix.nix.
