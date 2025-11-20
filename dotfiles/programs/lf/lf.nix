{ pkgs, ... }:

{
  # Add packages needed for the lf previewer
  home.packages = with pkgs; [
    ueberzug
    mediainfo
    imagemagick
    inkscape
    djvulibre
    lynx
    bat
    ffmpegthumbnailer
    poppler-utils
    gnome-epub-thumbnailer
    atool
    odt2txt
    gnupg
  ];

  programs.lf = {
    enable = true;
    settings = {
      preview = true;
      hidden = true;
      icons = true;
    };

    # Script to handle file previews
    previewer.source = ./scope;
  };

  xdg.configFile = {
    "lf/icons".source = ./icons;
  };

  imports = [
    ./keymap.nix
    ./commands.nix
  ];
}
