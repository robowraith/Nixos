{

  # Git configuration (shared settings)
  # User name and email are set in users/joachim/default.nix
  programs.git = {
    enable = true;
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.ff = "only";
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        cm = "commit -m";
        cam = "commit -am";
      };
    };
  };

}
