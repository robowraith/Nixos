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
      # Don't carry a remembered size across sessions (~/.cache/kitty/main.json).
      # A kitty sized on the 3840x2160 fullscreen monitor otherwise makes every
      # later kitty request that geometry, which HLWM keeps as floating_geometry
      # and then renders far wider than the virtual monitor it lands on.
      remember_window_size = "no";
      initial_window_width = 1000;
      initial_window_height = 700;
    };
  };
}
