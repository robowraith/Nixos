{
  # FZF configuration
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border"
      "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    ];
  };
}
