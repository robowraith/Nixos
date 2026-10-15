{
  lib,
  inputs,
  ...
}: {
  imports =
    [
      # Hardware-configuration.
      ./hardware-configuration.nix
      # Disk layout (used by nixos-anywhere to partition, and for fileSystems)
      inputs.disko.nixosModules.disko
      ./disko.nix
      # Shared configuration for all systems
      ../../shared
      # System groups this system belongs to
      ../../hostgroups/server
    ]
    ++ (
      # System specific configuration
      let
        modulesPath = ./modules;
        nixFilesInDir = lib.filterAttrs (
          name: type:
            type == "regular" && lib.hasSuffix ".nix" name
        ) (builtins.readDir modulesPath);
      in
        lib.mapAttrsToList (name: _: modulesPath + "/${name}") nixFilesInDir
    );
}
