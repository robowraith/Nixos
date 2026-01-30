{pkgs, ...}: {
  # Add packages needed for the lf previewer and file operations
  home.packages = with pkgs; [
    ueberzug
    mediainfo
    exiftool
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
    # Additional packages for lfrc functionality
    fzf
    ripgrep
    zoxide
    eza
    nsxiv
    mpv
    mupdf
    zathura
    libreoffice
    gimp
    xclip
    p7zip
    unrar
    unzip
    file
  ];

  programs.lf = {
    enable = true;

    settings = {
      preview = true;
      hidden = true;
      icons = true;
      shellopts = "-eu";
      ifs = "\n";
      scrolloff = 10;
      period = 1;
      hiddenfiles = ".*:*.aux:*.log:*.bbl:*.bcf:*.blg:*.run.xml";
      autoquit = true;
    };

    previewer.source = ./scope;

    extraConfig = ''
      set cleaner '~/.config/lf/cleaner'

      cmd on-cd &{{
        zoxide add "$PWD"
      }}

      cmd on-select &{{
        lf -remote "send $id set statfmt \"$(eza -ld --color=always "$f" | sed 's/\\/\\\\/g;s/"/\\"/g')\"" 
      }}
    '';

    # cmd fzf_search ${{
    #   cmd="rg --column --line-number --no-heading --color=always --smart-case"
    #   fzf --ansi --disabled --layout=reverse --header="Search in files" --delimiter=: \\
    #     --bind="start:reload([ -n {q} ] && $cmd -- {q} || true)" \\
    #     --bind="change:reload([ -n {q} ] && $cmd -- {q} || true)" \\
    #     --bind='enter:become(lf -remote "send $id select \"$(printf "%s" {1} | sed '\''s/\\/\\\\/g;s/\"/\\\"/g'\'')\"")'  \\
    #     --preview='cat -- {1}'
    # }}
    # '';
  };

  xdg.configFile = {
    "lf/icons".source = ./icons;
    "lf/cleaner" = {
      source = ./cleaner;
      executable = true;
    };
    "lf/scope" = {
      source = ./scope;
      executable = true;
    };
    "lf/lfub.sh" = {
      source = ./lfub.sh;
      executable = true;
    };
  };

  imports = [
    ./keymap.nix
    ./commands.nix
  ];
}
