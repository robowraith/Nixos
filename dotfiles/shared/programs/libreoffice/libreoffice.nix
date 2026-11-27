{
  config,
  pkgs,
  ...
}: {
  # Hunspell dictionaries for LibreOffice spell-checking (en + de, new orthography)
  home.packages = with pkgs.hunspellDicts; [
    en_US
    de_DE
  ];

  # LibreOffice looks for extra hunspell dictionaries via DICPATH
  home.sessionVariables.DICPATH = "${config.home.profileDirectory}/share/hunspell";
}
