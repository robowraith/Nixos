{lib, ...}: {
  imports =
    [
      # Hardware-configuration.
      ./hardware-configuration.nix
      # Shared configuration for all systems
      ../../shared
      # System groups this system belongs to
      ../../groups/home
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
