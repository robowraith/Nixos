{
  programs.keepassxc = {
    enable = true;
  };
  xdg.configFile = {
    "keepassxc/keepassxc.ini".source = ./keepassxc.ini;
  };
}
