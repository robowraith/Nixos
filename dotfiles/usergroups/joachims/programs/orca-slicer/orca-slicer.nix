{
  pkgs,
  lib,
  config,
  ...
}: {
  options.home.orcaSlicer.presetDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/Dokumente/OrcaSlicer";
    description = ''
      Verzeichnis auf dem CIFS-Share, in dem die zwischen den Hosts geteilten
      OrcaSlicer-Presets (Drucker, Filamente, Prozesse) liegen.
    '';
  };

  config = {
    home.packages = with pkgs; [
      orca-slicer
    ];

    # Die User-Presets liegen auf dem Share statt lokal, damit reason und
    # deepthought dieselben Drucker- und Filamentprofile sehen.
    #
    # mkOutOfStoreSymlink statt eines normalen Store-Symlinks: OrcaSlicer
    # schreibt beim Speichern eines Presets die JSON- und .info-Dateien neu,
    # das ginge auf einem read-only Store-Pfad nicht.
    xdg.configFile."OrcaSlicer/user/default".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.orcaSlicer.presetDir}/default";
  };
}
