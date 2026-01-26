{
  lib,
  pkgs,
  ...
}: {
  programs.kitty = {
    font = {
      name = lib.mkForce "FiraCode Nerd Font Mono";
      package = lib.mkForce pkgs.nerd-fonts.fira-code;
      size = lib.mkForce 13;
    };
    shellIntegration.enableFishIntegration = true;
    settings = {
      confirm_os_window_close = 0;
    };
  };
}
