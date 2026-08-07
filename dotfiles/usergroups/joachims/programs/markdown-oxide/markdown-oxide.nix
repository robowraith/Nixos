{pkgs, ...}: {
  home = {
    packages = [pkgs.markdown-oxide];

    # PKM vault at ~/notes. Daily-note location must stay in sync with the
    # ops-meeting-protocol skill in ~/code/ansible (daily/YYYY-MM-DD.md).
    file."notes/.moxide.toml".text = ''
      daily_notes_folder = "daily"
      dailynote = "%Y-%m-%d"
    '';

    # Helix only searches for `roots` markers up to its workspace dir (cwd when
    # no .git exists), so launching from a vault subdir would hand the LSP that
    # subdir as root. A .helix dir pins the workspace to the vault itself.
    file."notes/.helix/config.toml".text = "";
  };

  programs = {
    helix.languages = {
      language-server.markdown-oxide.command = "${pkgs.markdown-oxide}/bin/markdown-oxide";
      language = [
        {
          name = "markdown";
          language-servers = ["markdown-oxide"];
          # ~/notes is not a git repo — without a root marker helix anchors the
          # LSP at the cwd, so oxide indexes only a subdir and links unresolve.
          roots = [".moxide.toml" ".obsidian"];
        }
      ];
    };

    # Open today's/yesterday's daily note from any shell, with cwd temporarily
    # in the vault so the LSP gets the right root.
    fish.functions.today = ''
      pushd ~/notes
      mkdir -p daily
      $EDITOR daily/(date +%F).md
      popd
    '';

    fish.functions.yesterday = ''
      pushd ~/notes
      mkdir -p daily
      # Mind weekends: last journal before today, not literally 1 day back.
      switch (date +%u)
        case 1 # Monday -> last Friday
          set offset 3
        case 7 # Sunday (shouldn't occur, but just in case) -> Friday
          set offset 2
        case '*'
          set offset 1
      end
      $EDITOR daily/(date -d "-$offset days" +%F).md
      popd
    '';

    lf.keybindings = {
      gn = "cd ~/notes";
      # cd first: helix must be launched with cwd inside the vault, otherwise it
      # refuses to pass ~/notes as LSP root and wiki links don't resolve.
      gd = "$cd ~/notes && mkdir -p daily && $EDITOR daily/$(date +%F).md";
    };
  };
}
