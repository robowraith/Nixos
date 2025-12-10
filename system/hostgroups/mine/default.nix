{lib, ...}: {
  imports = let
    modulesPath = ./modules;
    nixFilesInDir = lib.filterAttrs (
      name: type:
        type == "regular" && lib.hasSuffix ".nix" name
    ) (builtins.readDir modulesPath);
  in
    lib.mapAttrsToList (name: _: modulesPath + "/${name}") nixFilesInDir;
}
