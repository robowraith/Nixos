{pkgs, ...}: {
  # Enable docker
  virtualisation.docker.enable = true;
  virtualisation.docker.package = pkgs.docker_29;

  # Add docker-compose to system packages
  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  # Configure docker to use journald logging
  virtualisation.docker.daemon.settings = {
    "log-driver" = "journald";
  };
}
