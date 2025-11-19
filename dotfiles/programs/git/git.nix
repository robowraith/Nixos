{

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Joachim Hoss";
        email = "robowraith@gmail.com";
      };
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
