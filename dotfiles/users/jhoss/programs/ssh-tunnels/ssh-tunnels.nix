{pkgs, ...}: {
  systemd.user.services = {
    ssh-tunnel-dc1 = {
      Unit = {
        Description = "SSH Tunnel to dc1 Kubernetes API";
        After = ["network.target"];
      };
      Service = {
        ExecStart = "${pkgs.openssh}/bin/ssh -N -L 64431:localhost:6443 joachim@dc1";
        Restart = "always";
        RestartSec = "10";
        StartLimitIntervalSec = "0";
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    ssh-tunnel-ac4 = {
      Unit = {
        Description = "SSH Tunnel to ac4 Kubernetes API";
        After = ["network.target"];
      };
      Service = {
        ExecStart = "${pkgs.openssh}/bin/ssh -N -L 64430:localhost:6443 joachim@ac4";
        Restart = "always";
        RestartSec = "10";
        StartLimitIntervalSec = "0";
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
