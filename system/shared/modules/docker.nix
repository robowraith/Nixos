{ pkgs, ... }:
{
  # Enable docker
  virtualisation.docker.enable = true;

  # Add docker-compose to system packages
  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  # Configure docker to use journald logging
  virtualisation.docker.daemon.settings = {
    "log-driver" = "journald";
  };
}
