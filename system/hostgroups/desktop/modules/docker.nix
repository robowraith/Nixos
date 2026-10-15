{pkgs, ...}: {
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29;
    # Use journald logging
    daemon.settings = {
      "log-driver" = "journald";
    };
  };

  # Add docker-compose to system packages
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
