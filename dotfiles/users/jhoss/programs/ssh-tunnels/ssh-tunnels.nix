{
  lib,
  pkgs,
  ...
}: let
  # Local port -> remote Kubernetes API for each cluster.
  tunnels = {
    dc1 = {
      localPort = 64431;
      description = "SSH Tunnel to dc1 Kubernetes API (development cluster)";
    };
    ac4 = {
      localPort = 64430;
      description = "SSH Tunnel to ac4 Kubernetes API (application cluster)";
    };
  };

  # Options that make an unattended tunnel actually die when it breaks.
  #
  # ServerAlive*: without these ssh never probes the peer, so after a suspend
  #   or a network change the process happily stays alive around a half-open
  #   TCP connection — systemd reports "running" while the forward is dead.
  #   This is the failure mode that required manual restarts. 10s x 2 means
  #   ssh exits ~20s after the link goes away and Restart=always takes over
  #   (~25s to a working tunnel, including RestartSec). Tighter than the usual
  #   15x3 on purpose: a hanging kubectl is worse than a probe every 10s.
  # ExitOnForwardFailure: if the local port is still held (e.g. a leftover
  #   process), fail instead of running a session with no forward at all.
  # BatchMode/ConnectTimeout: never block on a prompt, fail fast and retry.
  # ControlMaster/ControlPath: never join or become a multiplexed connection —
  #   a shared master's death is invisible here, and restarting this unit must
  #   not tear down interactive sessions.
  sshOptions = [
    "-o ServerAliveInterval=10"
    "-o ServerAliveCountMax=2"
    "-o ExitOnForwardFailure=yes"
    "-o ConnectTimeout=10"
    "-o BatchMode=yes"
    "-o ControlMaster=no"
    "-o ControlPath=none"
  ];

  mkTunnel = host: {
    localPort,
    description,
  }: {
    name = "ssh-tunnel-${host}";
    value = {
      Unit = {
        Description = description;
        # No After=network.target here: that unit does not exist in the user
        # manager, so it was a silent no-op. Reconnect handling is the restart
        # policy's job instead.
        #
        # StartLimitIntervalSec belongs in [Unit], not [Service] — systemd
        # ignored it there ("Unknown key") and applied the 5-starts-per-10s
        # default. 0 disables the limit so the unit never gives up.
        StartLimitIntervalSec = 0;
      };
      Service = {
        ExecStart = lib.concatStringsSep " " ([
            "${pkgs.openssh}/bin/ssh"
            "-N"
            "-L ${toString localPort}:localhost:6443"
          ]
          ++ sshOptions
          ++ ["joachim@${host}"]);

        # The key is passphrase-protected and only reaches the agent once
        # KeePassXC is unlocked, so early starts legitimately fail with
        # "Permission denied (publickey)". Set the socket on the unit rather
        # than relying on set-ssh-auth-sock.service having already pushed it
        # into the manager environment — that is a race at login.
        Environment = "SSH_AUTH_SOCK=%t/ssh-agent";

        Restart = "always";
        # Exponential backoff 5s -> 60s: fast recovery from a dropped link,
        # without hammering while the network is down or the agent has no key.
        RestartSec = 5;
        RestartSteps = 5;
        RestartMaxDelaySec = 60;
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
in {
  systemd.user.services = lib.mapAttrs' mkTunnel tunnels;
}
