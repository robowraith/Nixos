{ config, lib, pkgs, stateVersion, username, ...}:

let
  programs-path = ./programs;

  # Recursively finds all .nix files under a given path,
  # while ignoring the `_uninstalled` directory at the top level.
  collectNixFiles = path:
    let
      entries = builtins.readDir path;
    in
    builtins.concatMap (name:
      let
        newPath = path + "/${name}";
        type = entries.${name};
      in
      if type == "directory" then
        if path == programs-path && name == "_uninstalled" then
          []
        else
          collectNixFiles newPath
      else if type == "regular" && lib.strings.hasSuffix name ".nix" then
        [ newPath ]
      else
        []
    ) (builtins.attrNames entries);

  program-imports = collectNixFiles programs-path;
in
{
  imports = [
    ./modules/*
  ] ++ program-imports;

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = stateVersion;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
