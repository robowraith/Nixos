{pkgs, ...}: {
  services.polybar = {
    enable = true;
    script = "polybar bar &";
    config = ./config.ini;
    package = pkgs.polybar;
  };

  xdg.configFile = {
    "herbstluftwm/scripts/hlwm_tags.sh".source = ./hlwm_tags.sh;
  };
}
