{config, ...}: {
  # Auf deepthought hängen die Shares unter ~/Privat statt direkt im Home.
  home.orcaSlicer.presetDir = "${config.home.homeDirectory}/Privat/Dokumente/OrcaSlicer";
}
