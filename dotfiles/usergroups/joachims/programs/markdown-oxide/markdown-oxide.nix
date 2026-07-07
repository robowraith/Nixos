{pkgs, ...}: {
  home.packages = [pkgs.markdown-oxide];

  # PKM vault at ~/notes. Daily-note location must stay in sync with the
  # ops-meeting-protocol skill in ~/code/ansible (daily/YYYY-MM-DD.md).
  home.file."notes/.moxide.toml".text = ''
    daily_notes_folder = "daily"
    dailynote = "%Y-%m-%d"
  '';

  programs.helix.languages = {
    language-server.markdown-oxide.command = "${pkgs.markdown-oxide}/bin/markdown-oxide";
    language = [
      {
        name = "markdown";
        language-servers = ["markdown-oxide"];
      }
    ];
  };

  programs.lf.keybindings = {
    gn = "cd ~/notes";
    gd = "$mkdir -p ~/notes/daily && $EDITOR ~/notes/daily/$(date +%F).md";
  };
}
