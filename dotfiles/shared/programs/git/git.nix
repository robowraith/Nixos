{lib, ...}: {
  programs.git = {
    enable = true;

    settings = {
      init.defaultBranch = "main";
      pull.ff = "only";
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        cm = "commit -m";
        cam = "commit -am";
      };
      user = {
        name = lib.mkDefault "Joachim Hoss";
        email = lib.mkDefault "robowraith@gmail.com";
      };
    };
  };
}
