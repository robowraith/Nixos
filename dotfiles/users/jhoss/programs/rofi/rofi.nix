{pkgs, ...}: {
  xdg.configFile = {
    "rofi/joworkspace.rasi".source = ./joworkspace.rasi;
    "rofi/workspaces.fish".source = ./workspaces.fish;
  };
}
