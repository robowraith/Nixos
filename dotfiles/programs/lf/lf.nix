{ config, pkgs, lib, ... }:

let
  cfg = config.programs.lf;
in
{
  options.programs.lf = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable integration for lf (terminal file manager).";
    };

    preview = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable previews in lf.";
    };

    hidden = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show hidden files in lf.";
    };

    icons = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable icons in lf listing.";
    };

    previewer = lib.mkOption {
      type = lib.types.path;
      default = ./scope;
      description = "Path to the lf previewer script (scope).";
    };

    cleaner = lib.mkOption {
      type = lib.types.path;
      default = ./cleaner;
      description = "Path to the lf cleaner script used by previewers.";
    };

    lfubScript = lib.mkOption {
      type = lib.types.path;
      default = ./lfub.sh;
      description = "Path to the wrapper script that starts ueberzug for previews.";
    };

    iconsDir = lib.mkOption {
      type = lib.types.path;
      default = ./icons;
      description = "Directory containing lf icons to write to XDG config.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Packages needed for previewing files in lf
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
    ] ++ (config.home.packages or []);

    # Configure the lf program module with the selected settings
    programs.lf = {
      enable = cfg.enable;
      settings = {
        preview = cfg.preview;
        hidden = cfg.hidden;
        icons = cfg.icons;
      };

      previewer.source = cfg.previewer;
    };

    # Place config files under ~/.config/lf
    xdg.configFile = {
      "lf/icons".source = cfg.iconsDir;
      "lf/cleaner".source = cfg.cleaner;
      "lf/scope".source = cfg.previewer;
      "lf/lfub.sh".source = cfg.lfubScript;
      "lf/lfrc".text = lib.concatStringsSep "\n" [
        "# Generated lfrc from Nix options"
        ("set preview " + toString cfg.preview)
        ("set hidden " + toString cfg.hidden)
        ("set icons " + toString cfg.icons)
        "# previewer and cleaner scripts"
        "set previewer ~/.config/lf/scope"
        "set cleaner ~/.config/lf/cleaner"
        "# Additional keybindings/commands are provided by Nix module imports (keymap.nix and commands.nix)"
      ];
    };

    # Ensure scripts are executable
    home.file.".config/lf/cleaner".mode = "0755";
    home.file.".config/lf/scope".mode = "0755";
    home.file.".config/lf/lfub.sh".mode = "0755";
  };

  # Keep importing the keymap and commands fragments so they still define
  # `programs.lf.keybindings` and `programs.lf.commands` when present.
  imports = [
    ./keymap.nix
    ./commands.nix
  ];
}
