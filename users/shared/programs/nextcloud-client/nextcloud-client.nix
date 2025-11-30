{ config, pkgs, ... }:

{
  # Nextcloud client
  home.packages = [ pkgs.nextcloud-client ];
}
