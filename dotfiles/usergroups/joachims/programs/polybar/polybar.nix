{ pkgs, ... }:

{
  services.polybar = {
    enable = true;
    script = "polybar bar &";
    config = ./config.ini;
    package = pkgs.polybar;
  };
}
