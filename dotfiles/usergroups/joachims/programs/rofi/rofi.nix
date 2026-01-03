{pkgs, ...}:

{
  programs.rofi.enable = true;

  home.packages = with pkgs; [
    rofi-bluetooth
    rofi-power-menu
  ];

  xdg.configFile = {
    "rofi/themes/catppuccin.rasi".source = ./catppuccin.rasi;
    "rofi/jolauncher.rasi".source = ./jolauncher.rasi;
    "rofi/jossh.rasi".source = ./jossh.rasi;
    "rofi/jowindow.rasi".source = ./jowindow.rasi;
    "rofi/sshtunnel".source = ./sshtunnel;
  };
}
