{
  pkgs,
  lib,
  ...
}: {
  programs.obsidian = {
    enable = true;
    package = pkgs.obsidian;
    vaults.notes = {
      target = "notes";
      # Stylix sets baseFontSize from the system font size; force it here
      # since in-app changes don't persist once appearance.json is managed.
      settings.appearance.baseFontSize = lib.mkForce 18;
    };
  };

  # Stylix manages appearance.json declaratively once cssSnippets is set,
  # so in-app Settings > Appearance changes won't persist — edit here instead.
  stylix.targets.obsidian.vaultNames = ["notes"];
}
